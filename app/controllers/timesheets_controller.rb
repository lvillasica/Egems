class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]

  def index
    if user_signed_in?
      @employee_timesheets = current_user.timesheets
      check_invalid_timesheets
    else
      redirect_to signin_url
    end
  end

  def timein
    if request.post?
      time_now = Time.now
      date_today = Time.now.beginning_of_day
      user = current_user

      timesheet_latest = Timesheet.first(:conditions => ["employee_id=?", user.employee_id],
                                                                 :order => 'date desc, created_on desc')
      timesheet = user.timesheets.new(:date => date_today, :time_in => time_now)
      timesheet.save
    end
    redirect_to :timesheets
  end

  def timeout
    if request.post?
      @employee_timesheets = current_user.timesheets
      check_invalid_timesheets
      if @invalid_timesheets.empty?
        time_now = Time.now
        date_today = Time.now.beginning_of_day
        user = current_user

        timesheets_today =@employee_timesheets.where("employee_id=? and date<=? and time_in is not NULL and time_out is NULL", user.employee_id, date_today)
        if timesheet = timesheets_today.first
          timesheet.time_out = time_now
          timesheet.save
        end
      end
    end
    redirect_to :timesheets
  end

  def manual_timeout
    timesheet = Timesheet.find(params[:id])
    if time = params[:timeout]
      date = timesheet.date.localtime
      t_hour = time[:meridian].casecmp('AM').eql?(0) ? time[:hour] : (time[:hour].to_i + 12).to_s
      t_min = time[:min]
      timesheet.time_out = Time.local(date.year, date.month, date.day, t_hour, t_min)
      timesheet.save
    end
    redirect_to :timesheets
  end

  private

  def check_invalid_timesheets
    today = Time.now.beginning_of_day.utc
    @invalid_timesheets = @employee_timesheets.find(:all, :conditions => ["date < ? and time_in is not null and time_out is null", today])
    end
end
