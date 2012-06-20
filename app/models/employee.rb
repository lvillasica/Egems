class Employee < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_one :user
  has_many :timesheets, :table_name => 'employee_timesheets'
  has_and_belongs_to_many :shift_schedules, :join_table => 'employee_shift_schedules'
  belongs_to :shift_schedule

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def immediate_supervisor
    Employee.find_by_id(employee_supervisor_id)
  end

  def project_manager
    Employee.find_by_id(employee_project_manager_id)
  end
end
