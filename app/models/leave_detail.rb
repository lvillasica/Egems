class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  attr_accessible :leave_type, :leave_date, :end_date, :leave_unit, :details, :period

  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper
  include LeaveDetailsHelper

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  belongs_to :leave, :class_name => 'Leave', :foreign_key => :employee_truancy_id
  belongs_to :responder, :class_name => "Employee", :foreign_key => :responder_id
  has_and_belongs_to_many :responders, :class_name => "Employee",
                          :join_table => "employee_truancy_detail_responders",
                          :foreign_key => :employee_truancy_detail_id,
                          :association_foreign_key => :responder_id

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :leave_type, :leave_unit, :details
  validates_numericality_of :leave_unit
  validates_inclusion_of :period, :in => 0 .. 2, :message => "period is invalid."
  validate :invalid_leave

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_period
  before_validation :set_leave
  before_create :set_default_responders
  after_save :recompute_timesheets
  after_save :send_email_notification

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :active, includes(:leave).where("employee_truancies.status = 1")
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }
  scope :pending, where(:status => 'Pending')
  scope :asc, order(:leave_date, :period)
  scope :find_half_day, lambda { |date, period|
    where("leave_date = ? AND period = ?", date, period)
  }
  scope :filed_for, lambda {|date = Time.now.beginning_of_day|
    where(["leave_date <= ? and optional_to_leave_date >= ?", date.utc, date.utc])
  }

  # -------------------------------------------------------
  #  Constants
  # -------------------------------------------------------
  LEAVE_PERIOD = ["Whole Day", "AM", "PM", "Range"]

  # -------------------------------------------------------
  #  Class Methods
  # -------------------------------------------------------
  class << self
    include LeaveDetailsHelper
    def get_units_per_leave_date(non_working_dates)
      units_per_leave_date = {}
      self.active.each do |ld|
        local_leave_date = ld.leave_date.localtime.to_date
        local_end_date = ld.optional_to_leave_date.localtime.to_date rescue
                         (local_leave_date + ld.leave_unit.ceil.days) - 1.day
        if ld.leave_unit > 1
          leave_start = local_leave_date
          leave_end = local_end_date
          if leaves_for_hr_approval.include?(ld.leave_type)
            leave_dates = (leave_start .. leave_end).to_a
          else
            leave_dates = (leave_start .. leave_end).to_a - non_working_dates
          end
          leave_dates.each do |day|
            units_per_leave_date[day.to_s] = 1.0
          end
        elsif ld.leave_unit < 1 && units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] += ld.leave_unit
        elsif ld.leave_unit < 1 && !units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit
        else
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit
        end
      end
      return units_per_leave_date
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def leave_date=(date)
    self[:leave_date] = Time.parse(date.to_s).utc rescue nil
  end

  def end_date=(date)
    self[:optional_to_leave_date] = Time.parse(date.to_s).utc rescue nil
  end

  def end_date
    self[:optional_to_leave_date]
  end

  # returns {<mm/dd/yyyy> to <mm/dd/yyyy> or <mm/dd/yyyy AM/PM> or <mm/dd/yyyy>}
  def dated_on
    leave_start = leave_date.localtime.to_date
    leave_end = end_date.localtime.to_date
    range = (leave_start .. leave_end).to_a
    l_start_date = I18n.l(range.first, :format => :long_date_with_day)
    l_end_date = I18n.l(range.last, :format => :long_date_with_day) unless range.count == 1
    date = [l_start_date, l_end_date].compact.join(' to ')
    am_pm = {1 => "AM", 2 => "PM"}[period]
    [date, am_pm].compact.join(" ")
  end

  def get_responders
    if responder
      [responder.full_name]
    else
      responders.map(&:full_name)
    end
  end

  def set_leave
    self.leave = self.employee.leaves.type(leave_type).within_validity(leave_date).first
  end

  def set_period
    leave_date_local = leave_date.localtime.to_date
    end_date_local = end_date.localtime.to_date
    if (leave_date_local .. end_date_local).count > 1
      self.period = 3
    end
  end

  def set_default_responders
    if leaves_for_hr_approval.include?(self.leave_type)
      responders << @employee.hr_personnel
    else
      managers = [employee.project_manager, employee.immediate_supervisor].compact.uniq
      responders << managers
    end
  end

  def is_whole_day?
    @employee ||= employee
    return (period == 0 && leave_unit == 1) ||
      @employee.leave_details.filed_for(leave_date.localtime).sum(:leave_unit) == 1
  end

  def is_range?
    period == 3 && leave_unit > 1
  end

  def is_half_day?
    [1, 2].include?(period) && leave_unit == 0.5
  end

  def recompute_timesheets
    @employee ||= employee
    @leave ||= leave
    @leave_dates ||= (leave_date.localtime.to_date .. end_date.localtime.to_date)
    @day_offs ||= get_day_offs
    @holidays ||= get_holidays
    dates = @leave_dates.to_a - (@day_offs + @holidays)
    active_timesheet = dates.map { |date| @employee.timesheets.by_date(date.to_time).asc }
    if is_whole_day? || is_range?
      active_timesheet.flatten.compact.each do |entry|
        entry.update_column(:minutes_late, 0)
        entry.update_column(:duration, 0)
        entry.update_column(:minutes_excess, 0)
        entry.update_column(:minutes_undertime, 0)
        entry.put_remarks
      end
    elsif is_half_day?
      active_timesheet.select { |entries| !entries.blank? }.each do |entries|
        first_entry = entries.first
        last_entry = entries.last
        shift_schedule_detail = first_entry.shift_schedule_detail
        am_valid_timein = shift_schedule_detail.valid_time_in(first_entry.date)
        pm_valid_timein = shift_schedule_detail.valid_time_in(first_entry.date, false)
        first_timein = first_entry.time_in_without_adjustment.localtime
        last_timeout = last_entry.time_out.localtime rescue nil
        pm_start = pm_valid_timein.first + shift_schedule_detail.pm_time_allowance.minutes
        @late = entries.sum(&:minutes_late)
        @undertime = entries.sum(&:minutes_undertime)
        @excess = entries.sum(&:minutes_excess)
        if period == 1  # 1st Period Halfday Leave
          min_timein = am_valid_timein.first - shift_schedule_detail.am_time_duration.minutes
          max_timein = pm_valid_timein.last
          first_timein = min_timein if first_timein < min_timein
          @late = (first_timein > max_timein ? ((first_timein - max_timein) / 1.minute).floor : 0)
          if last_timeout
            total_break = (first_timein <= (pm_start - 1.hour) ? 1.hour : 0.hours)
            shift_total_time = shift_schedule_detail.shift_total_time(total_break)
            shift_total_time_half = shift_total_time - shift_schedule_detail.am_time_duration
            shift_start = first_timein > max_timein ? max_timein : first_timein
            shift_end = shift_start + shift_total_time_half.minutes
            within_shift_entries = entries.select { |e| e.is_within_range?(shift_start, shift_end) }
            valid_timeout = if @late > 0
              max_timein + shift_total_time_half.minutes
            else
              if total_break == 1.hour || first_timein > pm_start
                first_timein + shift_total_time_half.minutes
              else
                pm_start + shift_total_time_half.minutes
              end
            end
            last_within_shift = within_shift_entries.last
            if last_within_shift
              @undertime = last_within_shift.get_minutes_undertime(valid_timeout.utc)
            end
            @excess = last_entry.get_minutes_excess(valid_timeout.utc, @undertime)
          end
        elsif period == 2 && last_timeout  # 2nd Period Halfday Leave
          shift_total_time = shift_schedule_detail.shift_total_time
          shift_total_time_half = shift_total_time - shift_schedule_detail.pm_time_duration
          valid_timeout = if @late > 0
            am_valid_timein.last + shift_total_time_half.minutes
          else
            first_entry.time_in.localtime + shift_total_time_half.minutes
          end
          within_shift_entries = entries.select { |e| e.is_within_range?(nil, valid_timeout) }
          within_shift_entries.reverse_each do |e|
            if e.time_out.localtime < pm_start && valid_timeout <= pm_start
              within_shift_entries = [e]
              valid_timeout = valid_timeout - 1.hour
            else
              next if e.time_in.localtime > valid_timeout
            end
            break
          end
          last_within_shift = within_shift_entries.last
          if last_within_shift
            @undertime = last_within_shift.get_minutes_undertime(valid_timeout.utc)
          end
          @excess = 0
        end
        entries.compact.each do |entry|
          late = @late.to_i if entry.eql?(first_entry)
          undertime = @undertime.to_i if entry.eql?(last_entry)
          excess = @excess.to_i if entry.eql?(last_entry)
          entry.update_column(:minutes_late, late.to_i)
          entry.update_column(:minutes_excess, excess.to_i)
          entry.update_column(:minutes_undertime, undertime.to_i)
          entry.put_remarks
        end
      end
    end
  end

  def send_email_notification
    recipients = [employee]
    
    employee.hr_personnel.each do |hr| 
      recipients << hr unless employee.current_department_id == 4 
    end if leaves_for_hr_approval.include?(self.leave.leave_type)

    if employee.immediate_supervisor == employee.project_manager
      recipients << employee.project_manager
    else
      recipients.concat([employee.project_manager,employee.immediate_supervisor]).compact
    end

    recipients.compact.each do |recipient|
      begin
        LeaveDetailMailer.leave_approval(employee, self, recipient).deliver
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        errors[:base] << "There was a problem on sending the email notification to #{recipient.email}: #{e.message}"
        next
      end
    end
  end

  def invalid_leave
    @employee = self.employee
    @leave = self.leave || @employee.leaves.type(leave_type).within_validity(leave_date).first
    if validate_leave_type && validate_dates && validate_leave_validity && validate_active
      allocated = @leave.leaves_allocated.to_f
      consumed = @leave.leaves_consumed.to_f
      total_leaves = leave_unit.to_f + consumed + @leave.total_pending.to_f
      @leave_dates = (@leave_date_local .. @end_date_local)
      @day_offs = get_day_offs
      @holidays = get_holidays

      if leave_type != "AWOP"
        if !(["Magna Carta", "Maternity Leave"]).include?(leave_type)
          validate_date_range(:leave_date, valid_range)
          validate_date_range(:end_date, valid_range)
        end
        validate_leave_balance(total_leaves, allocated)
        validate_date_of_filing
      end
      validate_leave_conflicts
      validate_whole_day
      validate_half_day
      validate_leave_unit
      validate_non_working
    end
  end

private
  def validate_leave_type
    if @employee.leaves.type(leave_type).first.nil?
      errors[:leave_type] << "is invalid."
      return false
    else
      return true
    end
  end
  
  def validate_leave_validity
    if @leave.nil?
      errors[:base] << "You don't have enough leave credits for #{@leave_date_local}."
      return false
    else
      return true
    end
  end

  def validate_dates
    if valid_date?(:leave_date) && valid_date?(:end_date)
      @leave_date_local = leave_date.localtime.to_date
      @end_date_local = end_date.localtime.to_date
      if @leave_date_local > @end_date_local
        errors[:base] << "Leave date shouldn't be later than End date."
        return false
      else
        return true
      end
    end
  end

  def valid_date?(date_attr)
    begin
      Date.parse(self.send(date_attr).to_s)
      return true
    rescue
      errors[date_attr] << "is invalid."
      return false
    end
  end

  def valid_range
    date_from = @leave.date_from.localtime.to_date
    date_to = @leave.date_to.localtime.to_date

    case leave_type
    when "Vacation Leave", "Maternity Leave", "Magna Carta"
      min_date, max_date = Date.today + 1.day, date_to
    when "Sick Leave", "Emergency Leave"
      min_date, max_date = date_from, Date.today
    else
      min_date, max_date = date_from, date_to
    end
    return Range.new(min_date, max_date)
  end

  def validate_active
    if !@leave.active?
      errors[:base] << "Leave credits has already been expired."
      return false
    else
      return true
    end
  end

  def validate_date_range(date_attr, range)
    if range && !range.include?(self.send(date_attr).localtime.to_date)
      errors[date_attr] << "is invalid. Should be within
                            #{range.first} and #{range.last}."
    end
  end

  def validate_leave_balance(total, remaining)
    if total > remaining
      errors[:base] << "You don't have enough leave credits."
    end
  end

  def validate_leave_conflicts
    nwd = @day_offs + @holidays
    @units_per_leave_date = @employee.leave_details.get_units_per_leave_date(nwd)
    maxed_out_leaves = []
    units = ((@leave_dates.count > 1)? 1 : leave_unit)
    @leave_dates.each do |day|
      if (@units_per_leave_date[day.to_s].to_f + units) > 1
        maxed_out_leaves << day
      end
    end

    conflict_leaves = maxed_out_leaves & @leave_dates.to_a
    if !conflict_leaves.blank?
      dates = conflict_leaves.map { |d| format_date(d) }.compact.join(', ')
      errors[:base] << "You can no longer file leave(s) for
                        the ff. date(s): #{dates}"
    end
  end

  def validate_whole_day
    if [0, 3].include?(period) && leave_unit < 1
      errors[:leave_unit] << "should not be less than 1 if not a half day leave."
    end
  end

  def validate_half_day
    half_day = @employee.leave_details.find_half_day(leave_date, period).first
    if [1, 2].include?(period)
      if half_day
        errors[:base] << "You already have a #{period.ordinalize} period
                          half day leave on #{format_date leave_date}."
      end

      if @leave_date_local != @end_date_local
        errors[:base] << "Leave date should be equal to End date
                          if applying for a half day leave."
      end

      if leave_unit != 0.5
        errors[:leave_unit] << "should be equal to 0.5 if applying
                                for a half day leave."
      end
    end
  end

  def validate_date_of_filing
    if ["Sick Leave", "Emergency Leave"].include?(leave_type) && @end_date_local == Date.today
      if [0, 2].include?(period) || (period == 1 && Time.now < Time.parse("12pm"))
        errors[:base] << "Date of filing should always be after the
                          availment of leave."
      end
    end
  end

  def validate_leave_unit
    units = ([1, 2].include?(period) ? 0.5 : @leave_dates.count)
    if ["Maternity Leave", "Magna Carta"].include?(self.leave_type)
      total_days = units - 1 
    else
      total_days = units - (@day_offs + @holidays).uniq.count
    end
    total_days = 0.0 if total_days < 0
    if leave_unit != total_days
      errors[:leave_unit] << "is invalid."
    end
  end

  def validate_non_working
    nwd = @day_offs + @holidays
    if (@leave_dates.to_a - nwd).empty?
      errors[:base] << "You cannot file leave within non-working days."
    end
  end

  def get_day_offs
    day_offs = []
    day_offs_per_shift = @employee.day_offs_within(@leave.date_from .. @leave.date_to)

    day_offs_per_shift.each do | day_off |
      from = Date.parse(day_off[:from]) rescue nil
      to = Date.parse(day_off[:to]) rescue nil
      days = day_off[:days]

      @leave_dates.each do | date |
        if date >= from && date <= to && days.include?(date.wday)
          day_offs << date
        end
      end if from && to
    end
    day_offs
  end

  def get_holidays
    holidays = []
    emp_holidays = @employee.holidays_within(@leave.date_from .. @leave.date_to)
    holiday_dates = emp_holidays.map { | h | h.date.localtime.to_date }

    @leave_dates.each do | date |
      if holiday_dates.include?(date)
        holidays << date
      end
    end
    holidays
  end

end
