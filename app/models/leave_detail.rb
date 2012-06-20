class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :leave_type, :leave_date, :leave_unit
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :type, lambda { |type| where(:leave_type => type) }

end
