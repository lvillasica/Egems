class Timesheet < ActiveRecord::Base

  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end
  class NoTimeinError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out, :is_valid, :remarks

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
  has_many   :actions, :class_name => 'TimesheetAction',
                       :foreign_key => 'employee_timesheet_id'
  has_and_belongs_to_many :responders, :class_name => "Employee",
                          :join_table => "timesheet_actions",
                          :foreign_key => :employee_timesheet_id,
                          :association_foreign_key => :responder_id

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
  scope :last_entries, lambda { |timesheet|
    where("time_out < ? and Date(date) <= Date(?)",
           timesheet.time_out.utc, timesheet.date.utc)
  }
  scope :later_entries, lambda { |timesheet|
    where("time_in > ? and Date(date) >= Date(?)",
           timesheet.time_in.utc, timesheet.date.utc)
  }
  scope :within, lambda { |range|
    start_date, end_date = range
    asc
    .includes(:shift_schedule_detail)
    .where(["date between ? and ?",
             start_date.utc, end_date.utc])
  }

  scope :response_by, lambda { |supervisor|
    asc.includes(:responders)
    .where(["#{TimesheetAction.table_name}.responder_id = ?", supervisor.id])
  }

  scope :pending_manual,  includes(:responders).where(["#{TimesheetAction.table_name}.response = 'Pending'"])
  scope :approved_manual, includes(:responders).where(["#{TimesheetAction.table_name}.response = 'Approved'"])
  scope :rejected_manual, includes(:responders).where(["#{TimesheetAction.table_name}.response = 'Rejected'"])

  scope :editable_entries, lambda {
    ids = all.map { |t| t.id if t.actions.pending_or_rejected.any? }
    where(:id => ids.compact)
  }

  scope :exclude, lambda { |timesheets|
    if timesheets.any?
      where('id not in (?)', timesheets.map(&:id))
    else
      where(:id => all.map(&:id).compact)
    end
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
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime.to_date
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      time = nil
    end

    if time_out
      type = 'time_in'
      self.is_valid = 3     # manual time in
    else
      type = 'time_out'
      t_date = date.localtime
      self.is_valid = 2     # manual time out
    end

    self.attributes = { "#{type}" => time, "date" => t_date.beginning_of_day }
    self.responders << employee.responders_on(t_date).compact.uniq

    begin
      if self.save!
        self.class.time_in!(employee) if type.eql?("time_out")
        send_invalid_timesheet_notification(type)
        return true
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def manual_entry(attrs)
    timein = validate_time_attrs(attrs[:timein])
    timeout = validate_time_attrs(attrs[:timeout])
    errors[:time_in] << 'is invalid' unless timein
    errors[:time_out] << 'is invalid' unless timeout
    if timein && timeout
      invalid_timesheets = employee.timesheets.latest(timein).no_timeout +
                           employee.timesheets.previous(timein).no_timeout
      raise NoTimeoutError if invalid_timesheets.present?
      t_date = Time.parse(attrs[:timein][:date])
      self.attributes = {
        :date => t_date,
        :time_in => timein,
        :time_out => timeout,
        :is_valid => 4     # manual time in & out
      }
      self.responders << employee.responders_on(t_date).compact.uniq
      if self.save
        send_invalid_timesheet_notification("time in & out")
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def update_manual_entry(attrs)
    if [2, 3, 4].include?(is_valid)
      if attrs[:timein]
        time = validate_time_attrs(attrs[:timein])
        type = 'time_in'
      elsif attrs[:timeout]
        time = validate_time_attrs(attrs[:timeout])
        type = 'time_out'
      end

      if time
        if !is_changed?(type, time)
          errors[:base] << 'Nothing changed.'
          return true
        end

        self.attributes = { type.to_sym => time }
        if self.save
          reset_actions_response
          send_action_notification(type, employee, "updated")
          return true
        else
          return false
        end
      else
        errors[type.to_sym] << 'is invalid.'
        return false
      end
    else
      errors[:base] << 'Not a manual entry.'
      return false
    end
  end
  
  def reset_responders(responders=[])
    self.responders = responders.compact.uniq
    self.responders.reset
  end

  def reset_actions_response
    actions.each { |a| a.update_column(:response, 'Pending') unless a.is_pending? }
  end

  def validate_time_attrs(attrs)
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime.to_date
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      return Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      return nil
    end
  end

  def send_action_notification(type, action_owner, action)
    Delayed::Job.enqueue(TimesheetActionedMailingJob.new(self.id, type, action_owner.id, action))
    msg = "Sending email notifications..."
    Rails.cache.write("#{ action_owner.id }_timesheet_action_mailing_stat", ["enqueued", msg])
  end

  def send_invalid_timesheet_notification(type)
    Delayed::Job.enqueue(TimesheetRequestsMailingJob.new(self.id, type))
    msg = "Sending email notifications..."
    Rails.cache.write("#{ employee.id }_timesheet_request_mailing_stat", ["enqueued", msg])
  end

  def approve!(supervisor)
    type = case is_valid
           when 2 then 'time_out'
           when 3 then 'time_in'
           end
    actions.each do |action|
      action.response = 'Approved'
      time = (type == 'time_in') ? time_in_without_adjustment : time_out
      action.approved_time_out = time
      action.save
    end

    self.put_remarks
    send_action_notification(type, supervisor, "approved")
    return actions.present?
  end

  def reject!(supervisor)
    type = case is_valid
           when 2 then 'time_out'
           when 3 then 'time_in'
           end
    actions.each do |action|
      action.response = 'Rejected'
      if action.save
        timesheets_today = employee.timesheets.by_date(date.localtime).asc.reject{ |t| t.time_in > time_in }
        timesheets_today.each(&:zero_computations)
      end
    end

    self.put_remarks
    send_action_notification(type, supervisor, "rejected")
    return actions.present?
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

      exclude_lst = []
      exclude_lst << self unless self.new_record?
      last_entries = employee.timesheets.exclude(exclude_lst.compact)
                     .last_entries(self).desc
      last_entry = last_entries.first
      if last_entry && last_entry.time_out && time_in_without_adjustment < last_entry.time_out
        errors[:base] << "Time in should be later than last entries."
      end

      exclude_lst = exclude_lst + last_entries
      later_entry = employee.timesheets.exclude(exclude_lst.compact)
                    .later_entries(self).asc.first
      if later_entry && time_out > later_entry.time_in_without_adjustment
        lti = format_short_time_with_sec(later_entry.time_in_without_adjustment)
        errors[:base] << "Time out (#{t_o}) shouldn't be later than next entry's time in (#{lti})."
      end
    end
  end

  def compute_minutes
    if time_out
      timesheets_today = employee.timesheets.by_date(date.localtime).asc
      @timesheets_today = timesheets_today.reject{ |t| t.id == id || t.time_in > time_in }
      @first_timesheet = @timesheets_today.first || self

      if is_within_shift?
        if @timesheets_today.empty?
          @valid_time_out = get_valid_time_out
          self.duration = ((time_out - time_in) / 1.minute).floor
          self.minutes_undertime = get_minutes_undertime
          self.minutes_excess = get_minutes_excess
        else
          if timesheets_today.rejected_manual.empty?
            @valid_time_out = @first_timesheet.get_valid_time_out
            self.duration = ((time_out - @first_timesheet.time_in) / 1.minute).floor
            self.minutes_undertime = get_minutes_undertime
            self.minutes_excess = get_minutes_excess

            @timesheets_today.each(&:zero_computations)
          end
        end
      else
        if !is_work_day? or (is_work_day? && @timesheets_today.select(&:is_within_shift?).present? && timesheets_today.rejected_manual.empty?)
          undertimes = @timesheets_today.sum(&:minutes_undertime)
          self.duration = ((time_out - time_in) / 1.minute).floor
          self.minutes_undertime = 0
          self.minutes_excess = undertimes > 0 ? 0 : duration
        end
      end
    end
  end

  def zero_computations
    self.update_column(:duration, 0)
    self.update_column(:minutes_excess, 0)
    self.update_column(:minutes_undertime, 0)
  end

  def put_remarks
    @timesheets_today = employee.timesheets.by_date(date.localtime).asc
    @first_timesheet = @timesheets_today.first || self

    @remarks = Array.new
    @remarks << 'Late'  if @first_timesheet.is_late?
    @remarks << 'Undertime' if is_undertime?

    leaves = employee.leave_details.filed_for(date.localtime)
    if leaves.present?
      @remarks += remarks_leave_details(leaves)
    else
      @remarks << 'AWOL' if @first_timesheet == self && @first_timesheet.is_awol?
    end

    @remarks += remarks_manual_update

    @remarks = @remarks.uniq.compact.join(', ')
    if @first_timesheet.new_record?
      @first_timesheet.remarks = @remarks.to_s
    else
      @first_timesheet.update_column(:remarks, @remarks.to_s)
    end
  end

  def remarks_leave_details(leaves)
    r = Array.new
    if leaves.sum(&:leave_unit) == 0.5
      leave = leaves.first
      case leave.status
      when 'Pending'
        r << 'Leave Filed'
      when 'Approved'
        r << 'Leave Approved'
      when 'Rejected'
        r << 'Leave Rejected'
        periods = { 1 => 'AM', 2 => 'PM' }
        r << "#{periods[leave.period]} AWOL" if @timesheets_today.empty?
      end

      if @first_timesheet == self && @first_timesheet.new_record?
        periods = { 1 => 'PM', 2 => 'AM'}
        r << "#{periods[leave.period]} AWOL"
      end
    else
      r << 'Leave Approved' if leaves.approved.present?
      r << 'Leave Filed' if leaves.pending.present?
      r << 'Leave Rejected' if leaves.rejected.present?
      r << 'AWOL' if r.include?('Leave Rejected') && @first_timesheet.new_record?
    end
    r
  end

  def remarks_manual_update
    r = Array.new
    if [2, 3, 4].include?(is_valid)
      @timesheets_today ||= employee.timesheets.by_date(date.localtime).asc
      if @timesheets_today.pending_manual.present?
        r << 'For Verification'
      elsif @timesheets_today.rejected_manual.present?
        r << 'Not Verified'
      elsif @timesheets_today.approved_manual.present?
        r << 'Verified'
      end
    end
    r
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

  def is_editable?
    actions.pending_or_rejected.any?
  end

  def is_changed?(type, time)
    read_attribute(type.to_sym).localtime != time
  end

  def is_approved?
    actions.select { |action| !action.response.eql?('Approved') }.blank?
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
