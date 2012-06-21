class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  attr_accessor :end_date
  attr_accessible :leave_type, :leave_date, :end_date, :leave_unit, :details, :period
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :leave_type, :leave_date, :leave_unit
  validates_numericality_of :leave_unit
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }

end
