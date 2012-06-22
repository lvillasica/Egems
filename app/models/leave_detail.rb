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
  validates_presence_of :leave_type, :leave_date, :leave_unit, :details
  validates_numericality_of :leave_unit
  validate :invalid_leave
  
  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_period
  before_create :set_leave
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }
  scope :pending, where(:status => 'Pending')
  scope :find_half_day, lambda { |date, period|
    where("leave_date = ? AND period = ?", date, period)
  }
  
  # -------------------------------------------------------
  #  Class Methods
  # -------------------------------------------------------
  class << self
    def get_whole_days
      whole_days = []
      self.all.each do |ld|
        if ld.leave_unit == 1
          whole_days << ld.leave_date.localtime.to_date
        elsif ld.leave_unit > 1
          startDate = ld.leave_date.localtime.to_date
          endDate = startDate + ld.leave_unit.days
          (startDate ... endDate).each do |day|
            whole_days << day
          end
        end
      end
      return whole_days
    end
  end
  
  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def set_leave
    self.leave = self.employee.leaves.type(self.leave_type).first
  end
  
  def set_period
    if self.leave_unit > 1
      self.period = 3
    elsif self.leave_date.eql?(self.end_date)
      self.period = 0
    end
  end
  
  def invalid_leave
    @leave = self.leave || self.employee.leaves.type(self.leave_type).first
    allocated = @leave.leaves_allocated.to_f
    consumed = @leave.leaves_consumed.to_f
    pending_leaves = @leave.leave_details.pending
    pending_leave_units = pending_leaves.sum(:leave_unit).to_f
    remaining_leaves = allocated - consumed
    total_leaves = leave_unit.to_f + consumed + pending_leave_units
    whole_days = @leave.leave_details.get_whole_days
    if leave_unit >= 1
      startDate = leave_date.localtime.to_date
      endDate = startDate + leave_unit.days
      leave_dates = (startDate ... endDate).to_a
      conflict_leaves = whole_days & leave_dates
    end
    
    if total_leaves > remaining_leaves
      errors[:base] << "Not enough leave balance."
    end
    
    if !conflict_leaves.blank?
      dates = conflict_leaves.map { |d| format_date(d) }.compact.join(', ')
      errors[:base] << "You already have filed scheduled leaves for
                        the ff. date(s): #{dates}"
    end
    
    if [1,2].include?(period) && @leave.leave_details.find_half_day(leave_date, period).first
      errors[:base] << "You already have a #{period.ordinalize} period
                        half day on #{format_date leave_date}."
    end
  end

end
