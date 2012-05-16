class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  def index
    if user_signed_in?
      user = current_user
      date_today = Date.today.beginning_of_day
      time_now = Time.now
      @employee_timesheets = user.timesheets
    else
      redirect_to signin_url
    end
  end

  def timein
    date_today = Date.today.beginning_of_day
    time_now = Time.now
    user = current_user

    timesheet_today =Timesheet.where(:employee_id => user.employee_id, :date => date_today)
    timesheet_previous = Timesheet.first(:conditions => ["employee_id=? and date<=?", user.employee_id, date_today],
                                                                      :order => 'date desc, created_on desc')
    timesheet = user.timesheets.new(:date => date_today, :time_in => time_now)
    timesheet.save
    redirect_to :timesheets
  end

  def timeout
    date_today = Date.today.beginning_of_day
    time_now = Time.now
    user = current_user

    timesheets_today =Timesheet.where("employee_id=? and date<=? and time_in is not NULL and time_out is NULL", user.employee_id, date_today)
    if timesheet = timesheets_today.first
      timesheet.time_out = time_now
      timesheet.save
    end
    redirect_to :timesheets
  end
end
