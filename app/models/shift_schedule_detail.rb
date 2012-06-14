class ShiftScheduleDetail < ActiveRecord::Base

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :shift_schedule

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def shift_total_time
    am_time_duration + pm_time_duration + (1.hour/1.minute)
  end

  def valid_time_in(timesheet)
    if am_time_start && pm_time_start
      s_time = am_time_start - am_time_allowance.minutes
      e_time = am_time_start + am_time_allowance.minutes

      date = timesheet.date.localtime.beginning_of_week + (day_of_week - 1).days
      time_start = Time.local(date.year, date.month, date.day, s_time.hour, s_time.min)
      time_end = Time.local(date.year, date.month, date.day, e_time.hour, e_time.min)
      [time_start, time_end]
    end
  end

  def valid_time_out(timesheet)
    if am_time_start && pm_time_start
      s_time = pm_time_start + pm_time_duration.minutes - pm_time_allowance.minutes
      e_time = pm_time_start + pm_time_duration.minutes + pm_time_allowance.minutes

      date = timesheet.date.localtime.beginning_of_week + (day_of_week - 1).days
      time_start = Time.local(date.year, date.month, date.day, s_time.hour, s_time.min)
      time_end = Time.local(date.year, date.month, date.day, e_time.hour, e_time.min)
      [time_start, time_end]
    end
  end
end
