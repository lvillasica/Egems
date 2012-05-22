class Timesheet < ActiveRecord::Base
  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :user, :foreign_key => :employee_id

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest, :conditions => ["Date(date) = Date(?)", Time.now.utc]


  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  def self.time_in!(user)
    latest =  user.timesheets.latest(:order => 'date desc, created_on desc').first
    raise NoTimeoutError if latest and latest.time_out.nil?
    timesheet = user.timesheets.new(:date => Time.now.utc, :time_in => Time.now.utc)
    timesheet.save!
  end
end
