class Timesheet < ActiveRecord::Base
  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end
  class NoTimeinError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :time_in
  validates_presence_of :time_out, :on => :update
  validate :invalid_entries

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :shift_schedule
  belongs_to :shift_schedule_detail
  belongs_to :next_day_shift_schedule, class_name: 'ShiftSchedule'
  belongs_to :next_day_shift_schedule_detail, class_name: 'ShiftScheduleDetail'
  belongs_to :employee

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :put_shift_details, :on => :create
  before_save :set_minutes_late, :on => :create
  before_save :update_shift_details, :on => :update
  before_save :compute_minutes

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'
  scope :asc, :order => 'date asc, time_in asc'
  scope :within, lambda { |range|
    start_date, end_date = range
    asc
    .includes(:shift_schedule_detail)
    .where(["date between ? and ?",
             start_date.utc, end_date.utc])
  }

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def time_in!(employee, force=false)
      latest_invalid_timesheets = employee.timesheets.latest.no_timeout
      raise NoTimeoutError if latest_invalid_timesheets.present?
      raise NoTimeoutError if employee.timesheets.previous.no_timeout.present? and !force
      employee.timesheets.create!(:date => Time.now.beginning_of_day.utc,
                                  :time_in => Time.now.utc)
    end

    def time_out!(employee)
      t_latest = employee.timesheets.latest.no_timeout
      raise NoTimeinError if t_latest.empty?
      timesheet = t_latest.desc.first
      timesheet.time_out = Time.now.utc
      timesheet.save!
    end


    def latest(time = Time.now)
      range = [time.monday, time.sunday]
      day = time.localtime.to_date.wday
      within(range).includes(:shift_schedule_detail)
                   .where("shift_schedule_details.day_of_week = ?", day).asc
    end

    def previous
      where("Date(date) < Date(?)", Time.now.yesterday.utc)
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def time_in
    begin
      shift = shift_schedule_detail
      time_in_original = read_attribute(:time_in).localtime
      if shift.present? && shift.day_of_week == to_wday
        shift_min = shift.valid_time_in(self).first
        time_in_original < shift_min ? shift_min : time_in_original
      else
        time_in_original
      end
    rescue => error
      nil
    end
  end

  def time_in_without_adjustment
    read_attribute(:time_in)
  end

  def manual_update(attrs={}, forced=nil)
    #TODO: invalid date & time format
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime.to_date
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      time = nil
    end

    type = time_out ? 'time_in' : 'time_out'
    t_date = time_out ? t_date : date.localtime
    self.attributes = { "#{type}" => time, "date" => t_date.beginning_of_day }

    begin
      if self.save!
        # Time in after manual timeout only if Time in is clicked.
        self.class.time_in!(employee) if type.eql?("time_out") && forced
        #send_invalid_timesheet_notification(type)
        return true
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def send_invalid_timesheet_notification(type)
    recipients = [employee]
    recipients << employee.immediate_supervisor
    recipients << employee.project_manager

    recipients.compact.each do |recipient|
      begin
      TimesheetMailer.invalid_timesheet(employee, self, type, recipient).deliver
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        errors[:base] << "Time entry was updated however there was problem with email notification to #{recipient.email}: #{e.message}"
        next
      end
    end
  end

  def invalid_entries
    if time_in_without_adjustment && time_out
      t_i, t_o = format_short_time_with_sec(time_in_without_adjustment), format_short_time_with_sec(time_out)
      if time_in_without_adjustment > time_out
        errors[:base] << "Time in (#{t_i}) shouldn't be later than Time out (#{t_o})."
      end

      if time_out > Time.now.utc
        errors[:base] << "Time out (#{t_o}) shouldn't be later than current time."
      end

      last_entry = employee.timesheets.order(:created_on).last
      if last_entry && last_entry.time_out && time_in_without_adjustment < last_entry.time_out
        errors[:base] << "Time in should be later than last entries."
      end
    end
  end

  def compute_minutes
    if time_out
      @timesheets_today = employee.timesheets.latest(date.localtime)
                                  .reject{ |t| t.id == id || t.time_in > time_in }
      @first_timesheet = @timesheets_today.first || self

      if is_within_shift?
        if @timesheets_today.empty?
          @valid_time_out = get_valid_time_out
          self.duration = ((time_out - time_in) / 1.minute).floor
          self.minutes_undertime = get_minutes_undertime
          self.minutes_excess = get_minutes_excess
        else
          @valid_time_out = @first_timesheet.get_valid_time_out
          self.duration = ((time_out - @first_timesheet.time_in) / 1.minute).floor
          self.minutes_undertime = get_minutes_undertime
          self.minutes_excess = get_minutes_excess

          @timesheets_today.each do |prev|
            prev.update_column(:duration, 0)
            prev.update_column(:minutes_excess, 0)
            prev.update_column(:minutes_undertime, 0)
          end
        end
      else
        if !is_work_day? or (is_work_day? && @timesheets_today.select(&:is_within_shift?).present?)
          undertimes = @timesheets_today.sum(&:minutes_undertime)
          self.duration = ((time_out - time_in) / 1.minute).floor
          self.minutes_undertime = 0
          self.minutes_excess = undertimes > 0 ? 0 : duration
        end
      end
    end
  end

  def set_minutes_late
    if is_first_entry? && is_work_day? && is_within_shift?
      max_time_in = shift_schedule_detail.valid_time_in(self).last
      self.minutes_late = (time_in > max_time_in) ? ((time_in - max_time_in) / 60).floor : 0
    end
  end

  def get_minutes_undertime
    t_undertime = ((@valid_time_out - time_out) / 1.minute).ceil
    t_undertime > 0 ? t_undertime : 0
  end

  def get_minutes_excess
    return 0 if minutes_undertime > 0
    t_excess = ((time_out - @valid_time_out) / 1.minute).floor
    t_excess > 0 ? t_excess : 0
  end

  def put_shift_details
    # TODO: timein at 1AM tuesday, day_of_week
    self.shift_schedule = employee.shift_schedule(date)
    self.shift_schedule_detail = shift_schedule.detail(to_wday)
    next_day = date.tomorrow
    self.next_day_shift_schedule = employee.shift_schedule(next_day)
    self.next_day_shift_schedule_detail = next_day_shift_schedule.detail(to_wday(next_day))
  end

  def update_shift_details
    shift_start = shift_schedule_detail.valid_time_in(self).first
    shift_end =  next_day_shift_schedule_detail.valid_time_in(self).first
    range = Range.new(shift_start, shift_end, true)

    if !time_out.nil? && !range.cover?(time_out.localtime)
      diff = time_out.localtime >= shift_start ? 1 : -1
      day = shift_start.to_date + diff.days
      self.shift_schedule = employee.shift_schedule(day)
      self.shift_schedule_detail = shift_schedule.detail(day.to_date.wday)
      self.date = day.to_time
      next_day = day.tomorrow
      self.next_day_shift_schedule = employee.shift_schedule(next_day)
      self.next_day_shift_schedule_detail = next_day_shift_schedule.detail(next_day.to_date.wday)
    end
  end

  def get_valid_time_out
    if minutes_late > 0
      shift_schedule_detail.valid_time_out(self).last
    else
      time_in.localtime + shift_schedule_detail.shift_total_time.minutes
    end
  end

  def is_within_shift?
    if is_work_day?
      shift_date = shift_schedule_detail.valid_time_in(self).first
      @timesheets_today ||= employee.timesheets.latest(shift_date.beginning_of_day)
                                    .reject{ |t| t.id == id || t.time_in > time_in }
      @first_timesheet ||= @timesheets_today.first || self

      in_min, in_max = shift_schedule_detail.valid_time_in(self)
      shift_start = @first_timesheet.time_in
      shift_start = shift_start > in_max ? in_max : shift_start
      shift_end = shift_start + shift_schedule_detail.shift_total_time.minutes

      shift = Range.new(shift_start, shift_end)
      shift.cover?(time_in.localtime)
    end
  end

  def is_work_day?
    # not holidays and rest days
    shift_schedule_detail.am_time_start.present? && shift_schedule_detail.pm_time_start.present? &&
    !is_holiday?
  end

  def is_holiday?
    !employee.branch.holidays.falls_on(date.localtime).first.nil?
  end

  def is_first_entry?
    employee.timesheets.latest(date.localtime).first.nil?
  end

  def to_wday(other_date=nil)
    (other_date || date).localtime.to_date.wday
  end
end
