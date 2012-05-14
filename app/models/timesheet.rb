class Timesheet < ActiveRecord::Base
  set_table_name 'employee_timesheets'

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :user, :foreign_key => :employee_id
end
