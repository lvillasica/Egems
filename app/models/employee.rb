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
  has_many :overtimes
  has_many :responded_leave_details, :class_name => 'LeaveDetail', :foreign_key => :responder_id
  has_and_belongs_to_many :for_response_leave_details, :class_name => 'LeaveDetail',
                          :join_table => 'employee_truancy_detail_responders',
                          :foreign_key => :responder_id,
                          :association_foreign_key => :employee_truancy_detail_id
  has_and_belongs_to_many :for_response_overtimes, :class_name => 'Overtime',
                          :join_table => 'overtime_actions',
                          :foreign_key => :responder_id,
                          :association_foreign_key => :employee_overtime_id

  belongs_to :job_position, :foreign_key => :current_job_position_id

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def immediate_supervisor
    Employee.find_by_id(employee_supervisor_id)
  end

  def project_manager
    Employee.find_by_id(employee_project_manager_id)
  end

  def hr_personnel
    emp_branch_id = self.branch_id
    supervisor_hr_id = 61
    hr = Employee.joins('LEFT OUTER JOIN departments d on d.id = employees.current_department_id').
         where("employees.branch_id = #{ emp_branch_id } and d.code='HR' and current_job_position_id = #{supervisor_hr_id }")
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

  def total_pending_leaves
    leave_details.pending.sum(:leave_unit)
  end

  def holidays_within(date_range)
    branch.holidays.within(date_range)
  end

  def day_offs_within(date_range)
    day_offs_per_range = []
    scheds = shift_schedules.select("employee_shift_schedules.*").where([
      "employee_shift_schedules.start_date >= ? and employee_shift_schedules.end_date <= ?
      or employee_shift_schedules.shift_schedule_id = ?",
      date_range.first.localtime.utc, date_range.last.localtime.utc, shift_schedule_id
    ])

    scheds.each do | sched |
      day_offs = ShiftScheduleDetail.includes(:shift_schedule).where([
        "shift_schedules.id = ? and (shift_schedule_details.am_time_start is null
        or shift_schedule_details.pm_time_start is null) and
        (shift_schedule_details.am_time_duration = 0 or
        shift_schedule_details.pm_time_duration = 0)",
        sched.shift_schedule_id
      ])
      day_offs_per_range << {
        :from => sched.start_date,
        :to => sched.end_date,
        :days => day_offs.map(&:day_of_week)
      }
    end
    day_offs_per_range
  end

  def is_supervisor?
    job_position.is_supervisory == 1
  end

  def is_hr?
    current_department_id == 4
  end

  def is_supervisor_hr?
    current_department_id == 4 && current_job_position_id == 61
  end

  def can_approve_leaves?
    is_supervisor? or is_supervisor_hr?
  end

end
