class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  attr_accessible :leave_type, :leave_date, :end_date, :leave_unit, :details, :period, :status

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
  validates_inclusion_of :period, :in => 0 .. 3, :message => "period is invalid."
  validate :invalid_leave

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_period
  before_validation :set_leave
  before_create :set_created_on
  before_create :set_default_responders
  before_create :set_email_action_sent
  before_update :set_email_action_edited
  before_update :set_old_date_entries
  after_save :recompute_timesheets
  after_update :recompute_timesheets_without_leaves
  after_save :send_email_notification
  before_destroy :recompute_timesheets

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :active, includes(:leave).where("employee_truancies.status = 1")
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }
  scope :approved, where(:status => 'Approved')
  scope :rejected, where(:status => 'Rejected')
  scope :exclude_canceled, where("#{LeaveDetail.table_name}.status <> 'Canceled'")
  scope :pending, where("status = 'Pending' or status = 'HR Approved'")
  scope :approved_from_hr, where("status = 'HR Approved' or status = 'Approved'")
  scope :asc, order(:leave_date, :period)
  scope :find_half_day, lambda { |date, period|
    where("leave_date = ? AND period = ?", date, period)
  }

  scope :filed_for, lambda {|date = Time.now.beginning_of_day|
    where(["leave_date <= ? and optional_to_leave_date >= ?", date.utc, date.utc])
  }

  scope :exclude_ids, lambda { |ids|
    where(["#{LeaveDetail.table_name}.id NOT IN (?)", ids]) if ids.any?
  }

  scope :response_by, lambda { |supervisor|
    supervisor_id = supervisor.id
    special_leaves = Leave::SPECIAL_TYPES.map { |s| "#{s}"}
    condition = %Q{ #{LeaveDetailResponder.table_name}.responder_id = ? or
                    case when leave_type in (?)
                      then employees2.employee_supervisor_id = ? or employees2.employee_project_manager_id = ?
                    end
                  }

    includes(:responders).asc
    .joins("LEFT OUTER JOIN #{Employee.table_name} employees2 ON employees2.id = #{LeaveDetail.table_name}.employee_id")
    .where([condition, supervisor_id, special_leaves, supervisor_id, supervisor_id])
  }

  scope :within, lambda { |range|
    start_date, end_date = range
    if start_date and end_date
      asc
      .where(["leave_date between ? and ?",
               start_date.utc, end_date.utc])
    end
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
                         (local_leave_date + ld.leave_unit.to_f.ceil.days) - 1.day
        if ld.leave_unit.to_f > 1
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
        elsif ld.leave_unit.to_f < 1 && units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] += ld.leave_unit.to_f
        elsif ld.leave_unit.to_f < 1 && !units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit.to_f
        else
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit.to_f
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

  def end_date_was
    self.optional_to_leave_date_was
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
    self.responders = employee.responders_on(leave_date.localtime).compact.uniq
    if needs_hr_action?
      self.responders << employee.super_hr_personnel.compact.uniq unless employee.is_hr?
    end
  end


  def update_responders(responders=[])
    responders.compact.uniq.each do |responder|
      self.responders << responder unless self.responders.include?(responder)
    end
  end

  def reset_responders(responders=[])
    self.responders = responders.compact.uniq
    if needs_hr_action?
      self.responders << employee.super_hr_personnel.compact.uniq unless employee.is_hr?
    end
    self.responders.reset
  end

  def set_old_date_entries
    @old_leave_date_local = self.leave_date_was.localtime.to_date
    @old_end_date_local = self.end_date_was.localtime.to_date
  end

  def set_created_on
    self.created_on = Time.now.utc
  end

  def update_attributes_and_reset_status(attrs)
    attrs = attrs.symbolize_keys
    attrs.merge!(:status => 'Pending') unless status.eql?('Pending')
    self.responder_id = nil
    self.responded_on = nil
    # select only attributes to be changed to avoid malicious attacks.
    self.attributes = attrs.select do |a|
      tmp = [:leave_date, :end_date, :leave_unit, :details, :status]
      tmp << :period if [1, 2].include?(attrs[:period].to_i)
      tmp.include?(a)
    end

    if changed?
      self.period = attrs[:period]
      self.save
    else
      errors[:base] << 'Nothing changed.'
      return false
    end
  end

  def approve!(supervisor)
    if is_respondable_by?(supervisor)
      if needs_hr_action?
        if (status == 'Pending' && supervisor.is_hr?) or is_hr_approved?
          if supervisor.is_hr?
            self.status = 'HR Approved'
            update_responders(employee.responders_on(leave_date.localtime))
          else
            self.status = 'Approved'
          end
        else
          errors[:base] << 'Leave needs HR approval.'
        end
      else
        self.status = 'Approved'
      end
      self.responder = supervisor
      self.responded_on = Time.now
      if errors.empty?
        @email_action = "approved"
        @action_owner = supervisor
        if self.save(:validate => false)
          if is_approved?
            update_consumed_count(leave_unit.to_f)
          end
          return true
        end
      end
    else
      errors[:base] << 'Cannot approve own leave.' if employee == supervisor
    end
    return false
  end

  def reject!(supervisor)
    if is_respondable_by?(supervisor)
      self.status = 'Rejected'
      self.responder = supervisor
      self.responded_on = Time.now
      if supervisor.is_hr?
        update_responders(employee.responders_on(leave_date.localtime))
      end
      @email_action = 'rejected'
      @action_owner = supervisor
      if self.save(:validate => false)
        @leave_dates = (leave_date.localtime.to_date .. end_date.localtime.to_date)
        recompute_timesheets_without_leaves(@leave_dates.to_a)
        return true
      end
    else
      errors[:base] << 'Cannot reject own leave. Cancel you leave instead.' if employee == supervisor
    end
    return false
  end

  def cancel!
    if is_cancelable?
      update_consumed_count(0-leave_unit) if is_approved?
      update_column(:status, 'Canceled')
      remove_response_attrs
      @leave_dates = (leave_date.localtime.to_date .. end_date.localtime.to_date)
      dates_without_leaves = @leave_dates.to_a
      recompute_timesheets_without_leaves(dates_without_leaves)
      @email_action = 'canceled'
      send_email_notification
      return true
    else
      errors[:base] = "#{leave_type} dated on #{dated_on} is not cancelable."
      return false
    end
  end

  def remove_response_attrs
    update_column(:responder_id, nil)
    update_column(:responded_on, nil)
  end

  def needs_hr_action?
    Leave::SPECIAL_TYPES.include?(leave_type) and !leave.w_docs
  end

  def is_whole_day?
    @employee ||= employee
    return (period == 0 && leave_unit.to_f == 1) ||
      @employee.leave_details.filed_for(leave_date.localtime).sum(:leave_unit) == 1
  end

  def is_range?
    period == 3 && leave_unit.to_f > 1
  end

  def is_half_day?
    [1, 2].include?(period) && leave_unit.to_f == 0.5
  end

  def is_cancelable?
    ['Pending', 'Approved', 'HR Approved'].include?(status) && with_time_entries? ||
    ['Pending', 'Approved', 'HR Approved'].include?(status) && leave_date.localtime.to_date > Date.today
  end

  def with_time_entries?
    init_leave_dates_req
    dates = @leave_dates.to_a - (@day_offs + @holidays)
    timesheet_by_dates = dates.map do |date|
      @employee.timesheets.by_date(date.to_time).asc
    end
    return timesheet_by_dates.flatten.compact.any?
  end

  def is_respondable_by?(supervisor)
    return false if employee == supervisor
    if is_pending? or is_hr_approved?
      if supervisor.is_supervisor_hr?
        return true if responders.include?(supervisor) && is_pending? && needs_hr_action?
      elsif supervisor.is_supervisor?
        return true if responders.include?(supervisor) && (is_pending? || (needs_hr_action? && is_hr_approved?))
      end
    end
    return false
  end

  def is_hr_approved?
    status == 'HR Approved'
  end

  def is_approved?
    status == 'Approved'
  end

  def is_rejected?
    status == 'Rejected'
  end

  def is_pending?
    status == 'Pending'
  end

  def is_canceled?
    status == 'Canceled'
  end

  def is_holidayed?
    status == 'Holiday'
  end

  def recompute_timesheets
    init_leave_dates_req
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

  def recompute_timesheets_without_leaves(dates_without_leaves = nil)
    init_leave_dates_req
    old_leave_dates = (@old_leave_date_local .. @old_end_date_local)
    dates_without_leaves ||= (old_leave_dates.to_a - @leave_dates.to_a)
    dates = dates_without_leaves - (@day_offs + @holidays)
    active_timesheet = dates.map { |date| @employee.timesheets.by_date(date.to_time).asc }
    active_timesheet.flatten.compact.each do |entry|
      entry.set_minutes_late
      entry.compute_minutes
      entry.update_column(:minutes_late, entry.minutes_late)
      entry.update_column(:duration, entry.duration)
      entry.update_column(:minutes_excess, entry.minutes_excess)
      entry.update_column(:minutes_undertime, entry.minutes_undertime)
      entry.put_remarks
    end
  end

  def update_consumed_count(num=1)
    leave.update_column(:leaves_consumed, leave.leaves_consumed.to_f + num.to_f)
  end

  def invalid_leave
    @employee = self.employee
    @leave = self.leave || @employee.leaves.type(leave_type).within_validity(leave_date).first
    if validate_leave_type && validate_dates && validate_leave_validity && validate_active
      allocated = @leave.leaves_allocated.to_f
      consumed = @leave.leaves_consumed.to_f
      total_leaves = (leave_unit.to_f - leave_unit_was.to_f) + consumed + @leave.total_pending.to_f
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

  def compute_unit
    @employee ||= employee
    @leave ||= leave
    @leave_dates ||= (leave_date.localtime.to_date .. end_date.localtime.to_date)
    non_working_days = (get_day_offs | get_holidays)
    @leave_dates.count - non_working_days.count
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
    @units_per_leave_date = @employee.leave_details.exclude_canceled
                            .exclude_ids([self.id])
                            .get_units_per_leave_date(nwd)
    maxed_out_leaves = []
    units = ((@leave_dates.count > 1)? 1 : leave_unit.to_f)
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
    if [0, 3].include?(period) && leave_unit.to_f < 1
      errors[:leave_unit] << "should not be less than 1 if not a half day leave."
    end
  end

  def validate_half_day
    half_day = @employee.leave_details.exclude_ids([self.id])
               .find_half_day(leave_date, period).first
    if [1, 2].include?(period)
      if half_day
        errors[:base] << "You already have a #{period.ordinalize} period
                          half day leave on #{format_date leave_date}."
      end

      if @leave_date_local != @end_date_local
        errors[:base] << "Leave date should be equal to End date
                          if applying for a half day leave."
      end

      if leave_unit.to_f != 0.5
        errors[:leave_unit] << "should be equal to 0.5 if applying
                                for a half day leave."
      end
    end
  end

  def validate_date_of_filing
    if ["Sick Leave", "Emergency Leave"].include?(leave_type) && @end_date_local == Date.today
      shift_sched_detail = @employee.shift_schedule.detail_by_day(@leave_date_local.wday)
      pm_start = shift_sched_detail.pm_time_start
      if [0, 2].include?(period) || (period == 1 && Time.now < Time.parse("#{pm_start.hour}:#{pm_start.min}"))
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
    if leave_unit.to_f != total_days
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

  def send_email_notification
    action_owner_id = @action_owner ? @action_owner.id : nil
    Delayed::Job.enqueue(LeaveDetailsMailingJob.new(self.id, @email_action, action_owner_id))
    job_for = ['approved', 'rejected'].include?(@email_action) ? "leave_request" : "leave_detail"
    msg = "Sending email notifications..."
    Rails.cache.write("#{ action_owner_id || employee.id }_#{ job_for }_mailing_stat", ["enqueued", msg])
  end

  def set_email_action_sent
    @email_action = "sent"
  end

  def set_email_action_edited
    @email_action = "edited" if @email_action == 'sent' or @email_action.nil?
  end

  def init_leave_dates_req
    @employee ||= employee
    @leave ||= leave
    @leave_dates ||= (leave_date.localtime.to_date .. end_date.localtime.to_date)
    @day_offs ||= get_day_offs
    @holidays ||= get_holidays
  end
end
