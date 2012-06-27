class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  attr_accessor :end_date
  attr_accessible :leave_type, :leave_date, :end_date, :leave_unit, :details, :period
  
  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  belongs_to :leave, :class_name => 'Leave', :foreign_key => :employee_truancy_id
  
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
  before_create :set_leave
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest, includes(:leave)
    .where("employee_truancies.date_from >= ? and employee_truancies.date_to <= ?",
            Time.now.beginning_of_year.utc, Time.now.end_of_year.utc)
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }
  scope :pending, where(:status => 'Pending')
  scope :asc, order(:leave_date, :period)
  scope :find_half_day, lambda { |date, period|
    where("leave_date = ? AND period = ?", date, period)
  }
  
  # -------------------------------------------------------
  #  Class Methods
  # -------------------------------------------------------
  class << self
    def get_units_per_leave_date
      units_per_leave_date = {}
      self.latest.each do |ld|
        local_leave_date = ld.leave_date.localtime.to_date
        if ld.leave_unit > 1
          startDate = local_leave_date
          endDate = startDate + ld.leave_unit.days
          (startDate ... endDate).each do |day|
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
  def set_leave
    self.leave = self.employee.leaves.type(self.leave_type).first
  end
  
  def set_period
    leave_date_local = leave_date.localtime.to_date
    end_date_local = end_date.to_date
    if (leave_date_local .. end_date_local).count > 1
      self.period = 3
    end
  end
  
  def invalid_leave
    @employee = self.employee
    @leave = self.leave || @employee.leaves.type(self.leave_type).first
    @leave_date_local = leave_date.localtime.to_date
    @end_date_local = end_date.to_date
    if validate_dates && validate_active
      allocated = @leave.leaves_allocated.to_f
      consumed = @leave.leaves_consumed.to_f
      pending_leaves = @leave.leave_details.latest.pending
      pending_leave_units = pending_leaves.sum(:leave_unit).to_f
      remaining_leaves = allocated - consumed
      total_leaves = leave_unit.to_f + consumed + pending_leave_units
      
      validate_date_range(:leave_date, valid_range)
      
      validate_date_range(:end_date, valid_range)
      
      validate_leave_balance(total_leaves, remaining_leaves)
      
      validate_leave_conflicts
      
      validate_whole_day
      
      validate_half_day
      
      validate_date_of_filing
      
      validate_leave_unit
    end
  end
  
private
  def validate_dates
    if valid_date?(:leave_date) && valid_date?(:end_date) && @leave_date_local > @end_date_local
      errors[:base] << "Leave date shouldn't be later than End date."
      return false
    end
    return true
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
    when "Vacation Leave"
      min_date = Date.today + 1.day
      max_date = date_to
      range = Range.new(min_date, max_date)
    when "Sick Leave", "Emergency Leave"
      min_date = date_from
      max_date = Date.today
      range = Range.new(min_date, max_date)
    end
    return range
  end
  
  def validate_active
    unless @leave.active?
      errors[:base] << "Leave credits has already been expired."
      return false
    end
    return true
  end
  
  def validate_date_range(date_attr, range)
    if range && !range.include?(self.send(date_attr).to_date)
      errors[date_attr] << "is invalid. Should be within
                        #{range.first} and #{range.last}."
    end
  end
  
  def validate_leave_balance(total, remaining)
    if total > remaining
      errors[:base] << "Not enough leave balance."
    end
  end
  
  def validate_leave_conflicts
    units_per_leave_date = @employee.leave_details.get_units_per_leave_date
    startDate = @leave_date_local
    endDate = startDate + leave_unit.ceil.days
    maxed_out_leaves = []
    leave_dates = (startDate ... endDate).to_a
    units = ((leave_dates.count > 1)? 1 : leave_unit)
    leave_dates.each do |day|
      if (units_per_leave_date[day.to_s].to_f + units) > 1
        maxed_out_leaves << day
      end
    end
    
    conflict_leaves = maxed_out_leaves & leave_dates
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
    half_day = @leave.leave_details.find_half_day(leave_date, period).first
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
    total_days = (@leave_date_local .. @end_date_local).count
    if !leave_unit == total_days
      errors[:leave_unit] << "is invalid."
    end
  end

end
