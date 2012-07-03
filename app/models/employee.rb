class Employee < ActiveRecord::Base

  attr_protected :employee_supervisor_id, :employee_project_manager_id, :current_job_position_id,
                 :current_department_id

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_one :user
  has_many :timesheets, :table_name => 'employee_timesheets'
  has_and_belongs_to_many :shift_schedules, :join_table => 'employee_shift_schedules'
  belongs_to :branch
  has_many :leaves, :class_name => 'Leave'
  has_many :leave_details
  has_many :responded_leave_details, :class_name => 'LeaveDetail', :foreign_key => :responder_id
  has_and_belongs_to_many :for_response_leave_details, :class_name => 'LeaveDetail',
                          :join_table => 'employee_truancy_detail_responders',
                          :foreign_key => :responder_id,
                          :association_foreign_key => :employee_truancy_detail_id

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def immediate_supervisor
    Employee.find_by_id(employee_supervisor_id)
  end

  def project_manager
    Employee.find_by_id(employee_project_manager_id)
  end

  def shift_schedule(date=Time.now)
    date = date.beginning_of_day
    shift_schedules.where([
      "? between employee_shift_schedules.start_date and employee_shift_schedules.end_date",
       (date + date.utc_offset).utc
    ]).first || ShiftSchedule.find_by_id(shift_schedule_id)
  end

  def schedule_range(shift)
    range = shift_schedules.select("employee_shift_schedules.*")
                           .where(["employee_shift_schedules.shift_schedule_id=?", shift.id])
    range.map { |r| Range.new(r.start_date, r.end_date) }
  end
end
