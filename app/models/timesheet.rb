class Timesheet < ActiveRecord::Base
  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end
  class NoTimeinError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :user, :foreign_key => :employee_id

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest,   :conditions => ["Date(date) = Date(?)", Time.now.beginning_of_day.utc]
  scope :previous, :conditions => ["Date(date) < Date(?)", Time.now.beginning_of_day.utc]
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  def self.time_in!(user, force=false)
    latest_invalid_timesheets = user.timesheets.latest.no_timeout
    raise NoTimeoutError if latest_invalid_timesheets.present?
    raise NoTimeoutError if user.timesheets.previous.no_timeout.present? and !force
    timesheet = user.timesheets.new(:date => Time.now.beginning_of_day.utc,
                                    :time_in => Time.now.utc)
    timesheet.save!
  end

  def self.time_out!(user)
    latest = user.timesheets.latest.no_timeout
    raise NoTimeinError if latest.empty?
    timesheet = latest.desc.first
    timesheet.time_out = Time.now.utc
    timesheet.save!
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def manual_update(attrs={})
    #TODO: invalid date & time format
    t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime
    t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
    t_min = attrs[:min]
    time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    type = time_out ? "time_in" : "time_out"
    self.attributes = { "date" => t_date.beginning_of_day, "#{type}" => time }
    if self.save!
      user = User.find_by_employee_id(employee_id)
      TimesheetMailer.invalid_timesheet(user, self, type).deliver
    end
  end
end
