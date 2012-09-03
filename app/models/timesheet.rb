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
  has_one    :overtime, :foreign_key => 'id', :primary_key => 'id'

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :put_shift_details, :on => [:create]
  before_save :set_minutes_late, :on => [:create]
  before_save :update_shift_details, :on => [:create, :update]
  before_save :compute_minutes, :on => [:create, :update]
  after_save  :recompute_minutes_for_leaves
  after_save  :put_remarks

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'time_in desc, created_on desc'
  scope :asc, :order => 'time_in asc'
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
    def time_in!(employee)
      raise NoTimeoutError if employee.timesheets.no_timeout.present?
      employee.timesheets.create!(:date => Time.now.beginning_of_day.utc,
                                  :time_in => Time.now.utc)
    end

    def time_out!(employee)
      t_latest = employee.timesheets.no_timeout
      raise NoTimeinError if t_latest.empty?
      timesheet = t_latest.asc.first
      timesheet.time_out = Time.now.utc
      timesheet.save!
    end

    def by_date(date)
      where("Date(date) = Date(?)", date.utc)
    end

    def latest(time = Time.now)
      ids = all.map do |t|
        if  time > t.shift_schedule_detail.valid_time_in(t.date).first and
           (time < t.next_day_shift_schedule_detail.valid_time_in(t.date).first or
            time < t.shift_schedule_detail.valid_time_out(t.date).last)
          t.id
        end
      end
      where(:id => ids.compact)
    end

    def previous(time = Time.now)
      ids = all.map do |t|
        if time > t.next_day_shift_schedule_detail.valid_time_in(t.date).first and
           time > t.shift_schedule_detail.valid_time_out(t.date).last
          t.id
        end
      end
      where(:id => ids.compact)
    end

    def unemptize(employee, time)
      return all if all.present? && !block_given?
      if block_given? && time.is_a?(Array)
        tgroup = Hash.new
        all.each do |timesheet|
          wday = yield(timesheet)
          if tgroup.has_key?(wday)
            tgroup[wday] << timesheet
          else
            tgroup[wday] = [timesheet]
          end
        end

        monday = time.first.localtime
        (0...7).map do |w|
          weekday = monday + w.days
          unless tgroup[weekday.wday]
            tgroup[weekday.wday] = [empty_new(employee, weekday)].compact
          end
        end
        tgroup = ActiveSupport::OrderedHash[tgroup.sort]
        tgroup.delete_if { |k,v| v.empty? }
      else
        timesheet = [empty_new(employee, time)].compact
      end
    end

    def empty_new(employee, time)
      date_hired = employee.date_hired.localtime
      unless time < (date_hired - date_hired.utc_offset)
        shift = employee.shift_schedule.detail(time)
        valid_time_out = shift.valid_time_out(time).last
        if Time.now > valid_time_out
          timesheet = employee.timesheets.new({ :date => time })
          timesheet.shift_schedule_detail = shift
          return nil unless timesheet.is_work_day?
          timesheet.put_remarks
        end
        timesheet
      end
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def time_in
    #return localtime of valid_time_in value based on shift
    begin
      time_in_original = read_attribute(:time_in).localtime
      if shift_schedule_detail.present? && !is_holiday?(time_in_original)
        shift_min = shift_schedule_detail.valid_time_in(date).first
        time_in_original < shift_min ? shift_min : time_in_original
      else
        time_in_original
      end
    rescue => error
      nil
    end
  end

  def time_in_without_adjustment
    #returns utc format of time_in as is from database
    read_attribute(:time_in)
  end

  def manual_update(attrs={})
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
        #Time in after manual timeout only if Time in is clicked.
        self.class.time_in!(employee) if type.eql?("time_out")
        send_invalid_timesheet_notification(type)
        return true
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def send_invalid_timesheet_notification(type)
    recipients = [employee]
    if employee.immediate_supervisor == employee.project_manager
      recipients << employee.project_manager
    else
      recipients.concat([employee.project_manager,employee.immediate_supervisor]).compact
    end

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
      @timesheets_today = employee.timesheets.by_date(date.localtime).asc
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

  def put_remarks
    @timesheets_today = employee.timesheets.by_date(date.localtime).asc
    @first_timesheet = @timesheets_today.first || self
    remarks_ = Array.new
    remarks_ << 'Late' if @first_timesheet.is_late?
    remarks_ << 'Undertime' if is_undertime?

    leaves = employee.leave_details.filed_for(date.localtime)
    if leaves.present?
      sum = leaves.sum(&:leave_unit)
      if sum == 0.5
        remarks_ << ((leaves.first.is_approved?) ? 'Leave Approved' : 'Leave Filed')
        periods = { 1 => 'PM', 2 => 'AM' }
        if @first_timesheet == self && @first_timesheet.new_record?
          period = periods[leaves.first.period]
          remarks_ << "#{period} AWOL"
        end
      else
        remarks_ << 'Leave Approved' if leaves.approved.present?
        remarks_ << 'Leave Filed' if leaves.pending.present?
      end
    else
      remarks_ << 'AWOL' if @first_timesheet == self && @first_timesheet.is_awol?
    end

    remarks_ = remarks_.uniq.compact.join(', ')
    if @first_timesheet.new_record?
      @first_timesheet.remarks = remarks_ unless remarks_.empty?
    else
      @first_timesheet.update_column(:remarks, remarks_)
    end
  end

  def recompute_minutes_for_leaves
    filed_leaves = employee.leave_details.filed_for(date.localtime)
    if filed_leaves.present?
      filed_leaves.each do |fl|
        fl.recompute_timesheets
      end
    end
  end

  def is_awol?
    ldate = date.localtime
    shift = employee.shift_schedule.detail_by_day(ldate.wday)
    valid_time_out = shift.valid_time_out(ldate).last
    date_hired = employee.date_hired.localtime

    if new_record?
      is_past = Time.now > valid_time_out
      is_after_hiring = date.localtime >= (date_hired - date_hired.utc_offset)
      return true if is_work_day? && is_past && is_after_hiring
    else
      return true if time_in_without_adjustment > valid_time_out
    end
    return false
  end

  def is_late?
    minutes_late > 0
  end

  def is_undertime?
    timesheets = @timesheets_today
    timesheets << self unless @timesheets_today.include?(self)
    timesheets.sum(&:minutes_undertime) > 0
  end

  def is_overtime?
    timesheets = @timesheets_today
    timesheets << self unless @timesheets_today.include?(self)
    timesheets.sum(&:minutes_excess) > 0
  end

  def set_minutes_late
    if is_first_entry? && is_work_day? && is_within_shift?
      max_time_in = shift_schedule_detail.valid_time_in(date).last
      self.minutes_late = (time_in > max_time_in) ? ((time_in - max_time_in) / 60).floor : 0
    end
  end

  def get_minutes_undertime(valid_time_out = nil)
    valid_time_out ||= @valid_time_out
    t_undertime = ((valid_time_out - time_out) / 1.minute).ceil
    t_undertime > 0 ? t_undertime : 0
  end

  def get_minutes_excess(valid_time_out = nil, t_undertime = nil)
    t_undertime ||= minutes_undertime
    return 0 if t_undertime > 0
    valid_time_out ||= @valid_time_out
    t_excess = ((time_out - valid_time_out) / 1.minute).floor
    t_excess > 0 ? t_excess : 0
  end

  def put_shift_details
    ldate = date.localtime
    timein = time_in_without_adjustment.localtime
    self.shift_schedule = employee.shift_schedule(ldate)
    self.shift_schedule_detail = shift_schedule.detail(timein)
    self.date = shift_schedule_detail.get_shift_date(ldate)

    ldate = date.localtime
    if employee.schedule_range(shift_schedule).detect { |s| s.cover?(ldate) }.nil?
      self.shift_schedule = employee.shift_schedule(ldate)
      self.shift_schedule_detail = shift_schedule.detail(timein)
      self.date = shift_schedule_detail.get_shift_date(ldate)
    end

    next_date = date.localtime.to_time.tomorrow
    adjust_next_day_shift(next_date)
  end

  def adjust_next_day_shift(ldate)
    wday = shift_schedule_detail.day_of_week
    next_wday = (wday == 6) ? 0 : (wday + 1)
    self.next_day_shift_schedule = employee.shift_schedule(ldate)
    self.next_day_shift_schedule_detail = next_day_shift_schedule.detail_by_day(next_wday)
  end

  def update_shift_details
    if time_out
      ldate = date.localtime
      timein = time_in_without_adjustment.localtime
      timeout = time_out.localtime
      shift_range = shift_schedule_detail.to_shift_range(ldate)
      shift_start = shift_range.first

      if !shift_range.cover?(timein) or (shift_range.cover?(timein) && !is_work_day?)
        scheduled = employee.schedule_range(shift_schedule).detect { |s| s.cover?(ldate) }
        if scheduled.nil?
          shift = employee.shift_schedule(ldate)
          shift_detail = shift.detail_by_day(shift_schedule_detail.day_of_week)
          shift_start = shift_detail.valid_time_in(ldate).first
        end

        max_end = next_day_shift_schedule_detail.valid_time_in(ldate).first
        diff = 0
        if shift_range.cover?(timein)
          diff -= 1 if timein < shift_start && timeout < shift_start
        else
          diff += 1 if timein > shift_start && timeout > max_end
          diff -= 1 if timein < shift_start && timeout < shift_start
        end

        if diff != 0
          self.date = ldate + diff.day
          ldate = date.localtime
          self.shift_schedule = employee.shift_schedule(ldate)
          self.shift_schedule_detail = shift_schedule.detail_by_day(ldate.to_date.wday)
          next_date = ldate.tomorrow
          adjust_next_day_shift(next_date)
        end
      end
    end
  end

  def get_valid_time_out
    if minutes_late > 0
      shift_schedule_detail.valid_time_out(date).last
    else
      time_in.localtime + shift_schedule_detail.shift_total_time.minutes
    end
  end

  def is_within_shift?
    if is_work_day?
      @timesheets_today ||= employee.timesheets.by_date(date.localtime)
                                    .reject{ |t| t.id == id || t.time_in > time_in }
      @first_timesheet ||= @timesheets_today.first || self
      time_rendered = @timesheets_today.sum(&:duration)
      return false if time_rendered >= shift_schedule_detail.shift_total_time

      in_min, in_max = shift_schedule_detail.valid_time_in(@first_timesheet.date)
      shift_start = @first_timesheet.time_in
      shift_start = shift_start > in_max ? in_max : shift_start
      shift_end = shift_start + shift_schedule_detail.shift_total_time.minutes

      shift = Range.new(shift_start, shift_end)
      shift.cover?(time_in.localtime)
    end
  end

  def is_within_range?(shift_start = nil, shift_end = nil)
    if is_work_day?
      @timesheets_today ||= employee.timesheets.by_date(date.localtime).asc
      @first_timesheet ||= @timesheets_today.first || self

      in_min, in_max = shift_schedule_detail.valid_time_in(@first_timesheet.date)
      unless shift_start
        shift_start = @first_timesheet.time_in
        shift_start = shift_start > in_max ? in_max : shift_start
      end
      shift_end ||= shift_start + shift_schedule_detail.shift_total_time.minutes

      shift = Range.new(shift_start, shift_end)
      shift.cover?(time_in.localtime)
    end
  end

  def is_work_day?
    !shift_schedule_detail.is_day_off? and !is_holiday?
  end

  def is_holiday?(ldate=nil)
    ldate ||= date.localtime
    !employee.branch.holidays.falls_on(ldate).first.nil?
  end

  def is_first_entry?
    employee.timesheets.by_date(date.localtime).first.nil?
  end
end
