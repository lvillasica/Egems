class ShiftScheduleDetail < ActiveRecord::Base

  attr_protected :shift_schedule_id

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
    date = get_shift_date(timesheet)
    if am_time_start && pm_time_start
      s_time = am_time_start - am_time_allowance.minutes
      e_time = am_time_start + am_time_allowance.minutes

      time_start = Time.local(date.year, date.month, date.day, s_time.hour, s_time.min)
      time_end = Time.local(date.year, date.month, date.day, e_time.hour, e_time.min)
      [time_start, time_end]
    else
      date = date.to_time
      [date, date.end_of_day]
    end
  end

  def valid_time_out(timesheet)
    date = get_shift_date(timesheet)
    if am_time_start && pm_time_start
      s_time = pm_time_start + pm_time_duration.minutes - pm_time_allowance.minutes
      e_time = pm_time_start + pm_time_duration.minutes + pm_time_allowance.minutes

      time_start = Time.local(date.year, date.month, date.day, s_time.hour, s_time.min)
      time_end = Time.local(date.year, date.month, date.day, e_time.hour, e_time.min)
      [time_start, time_end]
    else
      date = date.to_time
      [date, date.end_of_day]
    end
  end

  def get_shift_date(timesheet)
    t_date = timesheet.time_in_without_adjustment.localtime.to_date
    week_num = t_date.cweek
    d_week = (day_of_week == 0) ? 7 : day_of_week
    date = Date.commercial(t_date.year, week_num, d_week)
    (t_date.sunday? && date < t_date) ? (date + 1.week) : date
  end
end
