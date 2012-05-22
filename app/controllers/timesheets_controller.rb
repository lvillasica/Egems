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
      begin
        if Timesheet.time_in!(user)
          redirect_to :timesheets
        end
      rescue NoTimeoutError
        @invalid_timesheet = timesheet_latest
        render :template => 'timesheets/manual_timeout'
      end
    end
  end

  def timeout
    if request.post?
      time_now = Time.now
      date_today = time_now.beginning_of_day
      user = current_user

      timesheet_today = user.timesheets.first(:order => 'date desc, created_on desc',
                                                                        :conditions => ["date=? and time_out is null",
                                                                                                 date_today.utc])
      if timesheet_today and timesheet_today.time_in
        timesheet_today.time_out = time_now
        timesheet_today.save
        redirect_to :timesheets
      else
        @invalid_timesheet = user.timesheets.new(:date => date_today)
        render :template => 'timesheets/manual_timein'
      end
    end
  end

  def manual_timein
    time_now = Time.now
    date_today = time_now.beginning_of_day
    if time = params[:timein]
      date = time[:date] ? Date.parse(time[:date]).beginning_of_day : date_today
      t_hour = time[:meridian].casecmp('AM').eql?(0) ? time[:hour] : (time[:hour].to_i + 12).to_s
      t_min = time[:min]
      timesheet = current_user.timesheets.new(:date => date, :time_out => time_now)
      timesheet.time_in = Time.local(date.year, date.month, date.day, t_hour, t_min)
      timesheet.save
    end
    redirect_to :timesheets
  end

  def manual_timeout
    timesheet = Timesheet.find(params[:id])
    if time = params[:timeout]
      date = time[:date] ? Date.parse(time[:date]).beginning_of_day : timesheet.date.localtime
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
