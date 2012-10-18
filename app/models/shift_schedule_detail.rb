class ShiftScheduleDetail < ActiveRecord::Base

  attr_protected :shift_schedule_id

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :shift_schedule

  scope :asc, order('day_of_week asc')
  scope :desc, order('day_of_week desc')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def get_shift_date(datetime)
    t_date = datetime.localtime.to_date
    week_num = t_date.cweek
    d_week = (day_of_week == 0) ? 7 : day_of_week
    date = Date.commercial(t_date.year, week_num, d_week)
    (t_date.sunday? && date < t_date) ? (date + 1.week) : date
  end

  def is_day_off?
    (am_time_start.nil? || pm_time_start.nil?) and
    (am_time_duration == 0 || pm_time_duration == 0)
  end

  def next
    wday = (day_of_week == 6) ? 0 : (day_of_week + 1)
    shift_schedule.details.detect { |d| d.day_of_week == wday }
  end

  def previous
    wday = (day_of_week == 0) ? 7 : day_of_week
    wday -= 1
    shift_schedule.details.detect { |d| d.day_of_week == wday }
  end

  def shift_total_time(total_break = 1.hour)
    am_time_duration + pm_time_duration + (total_break / 1.minute)
  end

  def to_shift_range(datetime)
    shift_start = valid_time_in(datetime).first
    shift_end = valid_time_out(datetime).last
    Range.new(shift_start, shift_end)
  end

  def valid_time_in(datetime=Time.now, am = true)
    time_start, time_allowance = if am
      [am_time_start, am_time_allowance]
    else
      [pm_time_start, pm_time_allowance]
    end
    date = get_shift_date(datetime)
    if is_day_off?
      date = date.to_time
      [date, date + 1.day]
    else
      start = Time.local(date.year, date.month, date.day, time_start.hour, time_start.min)
      time_start = start - time_allowance.minutes
      time_end = start + time_allowance.minutes
      [time_start, time_end]
    end
  end

  def valid_time_out(datetime=Time.now)
    if is_day_off?
      valid_time_in(datetime)
    else
      valid_time_in(datetime).collect { |t| t + shift_total_time.minutes }
    end
  end
end
