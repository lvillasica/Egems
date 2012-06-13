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
  belongs_to :user, foreign_key: 'employee_id'

  belongs_to  :shift_schedule, foreign_key: 'shift_schedule_id'
  belongs_to  :shift_schedule_detail, foreign_key: 'shift_schedule_detail_id'

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :put_shift_details, :on => :create
  before_save :set_minutes_late, :on => :create
  before_save :compute_minutes
  before_update :update_shift_details

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest, lambda { |time = Time.now|
    range = Range.new(time.monday, time.sunday)
    day = time.localtime.to_date.wday
    ids = within(range).map { |t| t.id if t.shift_schedule_detail.day_of_week == day }
    where("id IN (#{ids.compact.join(',')})")
  }
  scope :previous, lambda {
    time = Time.now.yesterday
    time -= 1.day until (ids=latest(time)).present?
    where("id IN (#{ids.map(&:id).compact.join(',')})")
  }
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'
  scope :within, lambda { |range|
    where(["date between ? and ?", range.first.utc, range.last.utc])
  }

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def time_in!(user, force=false)
      latest_invalid_timesheets = user.timesheets.latest.no_timeout
      raise NoTimeoutError if latest_invalid_timesheets.present?
      raise NoTimeoutError if user.timesheets.previous.no_timeout.present? and !force
      timesheet = user.timesheets.new(:date => Time.now.beginning_of_day.utc,
                                      :time_in => Time.now.utc)
      timesheet.save!
    end

    def time_out!(user)
      latest = user.timesheets.latest.no_timeout
      raise NoTimeinError if latest.empty?
      timesheet = latest.desc.first
      timesheet.time_out = Time.now.utc
      timesheet.save!
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def time_in
    shift = shift_schedule_detail
    time_in_original = read_attribute(:time_in).localtime

    if shift && shift.day_of_week == date_wday && time_out && is_work_day?
      shift_min = shift.valid_time_in(self).first
      time_in_original < shift_min ? shift_min : time_in_original
    else
      time_in_original
    end
  end

  def time_in_without_adjustment
    read_attribute(:time_in)
  end

  def manual_update(attrs={}, forced=nil)
    #TODO: invalid date & time format
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      time = nil
    end
    type = time_out ? "time_in" : "time_out"
    self.attributes = { "date" => t_date.beginning_of_day, "#{type}" => time }
    begin
      if self.save!
        user = User.find_by_employee_id(employee_id)
        # Time in after manual timeout only if your manual timeout entry is for
        # the current shift or if no timesheet for the shift created yet.
        self.class.time_in!(user) if type.eql?("time_out") && forced
        return true
        # TODO: move to instance method and rescue exceptions
        TimesheetMailer.invalid_timesheet(user, self, type).deliver
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def invalid_entries
    if time_in && time_out
      t_i, t_o = format_short_time_with_sec(time_in), format_short_time_with_sec(time_out)
      if time_in > time_out
        errors[:base] << "Time in (#{t_i}) shouldn't be later than Time out (#{t_o})."
      end

      if time_out > Time.now.utc
        errors[:base] << "Time out (#{t_o}) shouldn't be later than current time."
      end

      user = User.find_by_employee_id(employee_id)
      last_entry = user.timesheets.order(:created_on).last
      if last_entry && last_entry.time_out && time_in < last_entry.time_out
        errors[:base] << "Time in should be later than last entries."
      end
    end
  end

  def compute_minutes
    if time_out
      user = User.find_by_employee_id(employee_id)
      @timesheets_today = user.timesheets.latest(date.localtime)
                              .reject{ |t| t.id == id }.sort_by(&:time_in)
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
        undertimes = @timesheets_today.sum(&:minutes_undertime)
        self.duration = ((time_out - time_in) / 1.minute).floor
        self.minutes_undertime = 0
        self.minutes_excess = undertimes > 0 ? 0 : duration
      end
    end
  end

  def set_minutes_late
    if is_first_entry? && is_within_shift?
      detail = self.shift_schedule_detail
      l_time_in = self.time_in.localtime
      t_in = Time.local(l_time_in.year, l_time_in.mon, l_time_in.day,
                        l_time_in.hour, l_time_in.min)
      max_time_in = detail.valid_time_in(self).last
      self.minutes_late = (t_in > max_time_in)? ((t_in - max_time_in) / 60).floor : 0
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
    self.shift_schedule_detail = ShiftScheduleDetail.find_by_day_of_week(date_wday)
    update_shift_details
  end

  def update_shift_details
    if is_work_day?
      shift_start = shift_schedule_detail.valid_time_in(self).first
      shift_end = shift_start + 24.hours
      range = Range.new(shift_start, shift_end, true)

      if !range.cover?(time_in_without_adjustment.localtime)
        if !time_out.nil? && !range.cover?(time_out.localtime)
          day = (date.localtime - 1.day).to_date.wday
          self.shift_schedule_detail = ShiftScheduleDetail.find_by_day_of_week(day)
        end
      end
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
      first_timesheet = @first_timesheet || self

      in_min, in_max = shift_schedule_detail.valid_time_in(self)
      shift_start = first_timesheet.time_in
      shift_start = shift_start > in_max ? in_max : shift_start
      shift_end = shift_start + shift_schedule_detail.shift_total_time.minutes

      shift = Range.new(shift_start, shift_end)
      shift.cover?(time_in.localtime)
    end
  end

  def is_work_day?
    !shift_schedule_detail.am_time_start.nil? && !shift_schedule_detail.pm_time_start.nil?
  end

  def is_first_entry?
    user = User.find_by_employee_id(employee_id)
    user.timesheets.latest(date.localtime).first.nil?
  end

  def date_wday
    date.localtime.to_date.wday
  end
end
