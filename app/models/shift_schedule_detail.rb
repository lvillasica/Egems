class ShiftScheduleDetail < ActiveRecord::Base

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :shift_schedule

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def total_hours
    am_time_duration + pm_time_duration + (1.hour/1.minute)
  end

  def valid_time_out
    pm_end = pm_time_start.localtime + pm_time_duration.minutes + pm_time_allowance.minutes
    date = Time.now.beginning_of_week + (day_of_week - 1).days
    Time.local(date.year, date.month, date.day, pm_end.hour, pm_end.min)
  end

end
