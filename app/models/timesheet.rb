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
  scope :latest,   :conditions => ["Date(date) = Date(?)", Time.now.utc]
  scope :previous, :conditions => ["Date(date) < Date(?)", Time.now.utc]
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  def self.time_in!(user, force=false)
    latest_invalid_timesheets = user.timesheets.latest.no_timeout
    if latest_invalid_timesheets.present?
      # TimesheetMailer.invalid_timesheet(user,latest_invalid_timesheets.first)
      raise NoTimeoutError
    end
    raise NoTimeoutError if user.timesheets.previous.no_timeout.present? and !force
    timesheet = user.timesheets.new(:date => Time.now.utc, :time_in => Time.now.utc)
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
    t_hour = attrs[:meridian].casecmp('AM').eql?(0) ? attrs[:hour] : (attrs[:hour].to_i + 12).to_s
    t_min = attrs[:min]
    time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    self.time_out = time unless time_out
    self.time_in = time unless time_in
    self.save!
  end
end
