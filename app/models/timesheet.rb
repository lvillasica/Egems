class Timesheet < ActiveRecord::Base
  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end
  class NoTimeinError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :time_in
  validates_presence_of :time_out, :on => :update
  validate :invalid_entries

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :user, foreign_key: 'employee_id'

  belongs_to  :shift_schedule, foreign_key: 'shift_schedule_id'
  belongs_to  :shift_schedule_detail, foreign_key: 'shift_schedule_detail_id'

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_create :put_shift_details
  before_update :compute_minutes

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest, lambda { |time = Time.now.beginning_of_day|
    where("Date(date) = Date(?)", time.utc)
  }
  scope :previous, :conditions => ["Date(date) < Date(?)", Time.now.beginning_of_day.utc]
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'
  scope :within, lambda { |range|
    where(["Date(date) between Date(?) and Date(?)", range.first.utc, range.last.utc])
  }

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def time_in!(user, force=false)
      latest_invalid_timesheets = user.timesheets.latest.no_timeout
      raise NoTimeoutError if latest_invalid_timesheets.present?
      raise NoTimeoutError if user.timesheets.previous.no_timeout.present? and !force
      timesheet = user.timesheets.new(:date => Time.now.beginning_of_day.utc,
                                      :time_in => Time.now.utc)
      timesheet.save!
    end

    def time_out!(user)
      latest = user.timesheets.latest.no_timeout
      raise NoTimeinError if latest.empty?
      timesheet = latest.desc.first
      timesheet.time_out = Time.now.utc
      timesheet.save!
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def manual_update(attrs={})
    #TODO: invalid date & time format
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      time = nil
    end
    type = time_out ? "time_in" : "time_out"
    self.attributes = { "date" => t_date.beginning_of_day, "#{type}" => time }
    begin
      if self.save!
        user = User.find_by_employee_id(employee_id)
        # Time in after manual timeout only if your manual timeout entry is for
        # the current day.
        if type.eql?("time_out") && time.today?
          self.class.time_in!(user) rescue NoTimeoutError
        end
        # TODO: move to instance method and rescue exceptions
        TimesheetMailer.invalid_timesheet(user, self, type).deliver
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def invalid_entries
    if time_in && time_out
      t_i, t_o = format_short_time_with_sec(time_in), format_short_time_with_sec(time_out)
      if time_in > time_out
        errors[:base] << "Time in (#{t_i}) shouldn't be later than Time out (#{t_o})."
      end

      if time_out > Time.now.utc
        errors[:base] << "Time out (#{t_o}) shouldn't be later than current time."
      end

      user = User.find_by_employee_id(employee_id)
      last_entry = user.timesheets.order(:created_on).last
      if last_entry && last_entry.time_out && time_in < last_entry.time_out
        errors[:base] << "Time in should be later than last entries."
      end
    end
  end

  def compute_minutes
    if time_out
      self.duration = (time_out - time_in) / 1.minute
      user = User.find_by_employee_id(employee_id)
      timesheets_today = user.timesheets.latest(date.localtime)
                             .reject{ |t| t.id == id }.select(&:is_within_shift?)
      valid_time_out = shift_schedule_detail.valid_time_out

      if time_out < valid_time_out
        self.minutes_undertime = (valid_time_out - time_out) / 1.minute
        self.minutes_excess = 0
      elsif time_out > valid_time_out
        self.minutes_undertime = 0
        self.minutes_excess = (time_out - valid_time_out) / 1.minute
      end
    end
  end

  def put_shift_details
    self.shift_schedule_detail = ShiftScheduleDetail.find(date_wday)
  end

  def is_within_shift?
    shift = shift_schedule_detail
    shift_start = shift.am_time_start - shift.am_time_allowance.minutes
    shift_end = shift.pm_time_start + shift.pm_time_duration.minutes + shift.pm_time_allowance.minutes

    time_start = Time.parse I18n.l(shift_start, :format => :short)
    timein = Time.parse I18n.l(time_in, :format => :short)
    time_end = Time.parse I18n.l(shift_end, :format => :short)

    shift_schedule = Range.new(time_start, time_end)
    shift_schedule.cover?(timein)
  end

  private
  def date_wday
    date.localtime.to_date.wday
  end
end
