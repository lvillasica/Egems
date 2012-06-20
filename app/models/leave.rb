class Leave < ActiveRecord::Base

  self.table_name = 'employee_truancies'
  attr_accessible :leave_type, :date_from, :date_to, :leaves_allocated
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee

end
