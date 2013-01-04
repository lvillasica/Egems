class ShiftScheduleDetail < ActiveRecord::Base

  attr_protected :shift_schedule_id, :id
  attr_accessible :am_time_start, :am_time_duration, :am_time_allowance, :differential_rate,
                  :pm_time_start, :pm_time_duration, :pm_time_allowance, :day_of_week


  validates_inclusion_of :day_of_week, :in => 0..6
  validates_numericality_of :am_time_duration, :am_time_allowance, :pm_time_duration, :pm_time_allowance,
                           :greater_than_or_equal_to => 0, :only_integer => true
  validate :time_starts_and_duration

  before_save :times_for_rds

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :shift_schedule

  scope :asc, order('day_of_week asc')
  scope :desc, order('day_of_week desc')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def am_time_start=(value)
    value = begin v=Time.parse(value) rescue nil end
    write_attribute(:am_time_start, value)
  end

  def pm_time_start=(value)
    value = begin v=Time.parse(value) rescue nil end
    if value && am_time_start && (value < am_time_start)
      #pm_time_start always greater than am_time_start, if it is lesser, then it means next day
      write_attribute(:pm_time_start, am_time_start + 1.day)
    end
    write_attribute(:pm_time_start, value)
  end

  def adjusted_pm_time_start
    pm = read_attribute(:pm_time_start)
    pm += 1.day if pm && pm < am_time_start
    pm
  end

  def times_for_rds
    if am_time_start.nil? && pm_time_start.nil?
      self.am_time_duration  = 0
      self.am_time_allowance = 0
      self.pm_time_duration  = 0
      self.pm_time_allowance = 0
    end
  end

  def time_starts_and_duration
    if am_time_start && pm_time_start
      errors[:base] << "AM Allowance must be less than AM duration" if am_time_allowance > am_time_duration
      errors[:base] << "PM Allowance must be less than PM duration" if pm_time_allowance > pm_time_duration

      end_time = adjusted_pm_time_start + pm_time_duration.minutes
      end_start_diff = (end_time - am_time_start) / 1.minute
      if end_start_diff == (9.hours/1.minute)
        min_pm_time = am_time_start + am_time_duration.minutes
        errors[:base] << "PM Time In must be after AM Time In + AM duration" if adjusted_pm_time_start <= min_pm_time
      else
        errors[:base] << "Schedule must have a total of 9 hours"
      end
    elsif am_time_start && pm_time_start.nil?
      errors[:base] << "PM Time In can't be empty."
    elsif pm_time_start && am_time_start.nil?
      errors[:base] << "AM Time In can't be empty."
    end
  end

  def day_name
    Date::DAYNAMES[day_of_week]
  end

  def abbr_day_name
    Date::ABBR_DAYNAMES[day_of_week]
  end

  def get_shift_date(datetime)
    t_date = datetime.to_date
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
    if am
      time_start, time_allowance = [am_time_start, am_time_allowance]
    else
      time_start, time_allowance = [pm_time_start, pm_time_allowance]
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
