class Leave < ActiveRecord::Base
  
  self.table_name = 'employee_truancies'
  attr_accessible :leave_type, :date_from, :date_to, :leaves_allocated
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  has_many :leave_details, :foreign_key => :employee_truancy_id
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :type, lambda { |type| where(:leave_type => type).order(:id, :created_on) }

end
