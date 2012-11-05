class EmployeeShiftSchedule < ActiveRecord::Base

  attr_accessible :start_date, :end_date, :employee_id

  belongs_to :shift_schedule
  belongs_to :employee

  validate :dates_and_values
  after_save :recompute_timesheets

  include ApplicationHelper

  def dates_and_values
    sched = self.class.where(["employee_id=?", employee_id])
    taken_dates = sched.map { |s| Range.new(s.start_date.to_date, s.end_date.to_date) }

    dstart = start_date.to_date
    dend = end_date.to_date
    taken_dates.each do |d|
      if d.include?(dstart) or d.include?(dend)
        errors[:base] << "Employee has shift schedule for #{format_date d.first} to #{format_date d.last}"
        break
      end
    end
  end

  def recompute_timesheets
    lstart = start_date.to_date.to_time
    lend = end_date.to_date.to_time
    range = [lstart, lend]
    if (timesheets=employee.timesheets.within(range)).present?
      timesheets.each do |timesheet|
        timesheet.put_shift_details
        timesheet.set_minutes_late
        timesheet.save
      end
    end
  end
end
