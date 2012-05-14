class Timesheet < ActiveRecord::Base
  self.table_name = 'employee_timesheets'

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :user, :foreign_key => :employee_id
end
