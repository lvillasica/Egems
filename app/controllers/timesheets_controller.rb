class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]

  def index
    if user_signed_in?
      @employee_timesheets = current_user.timesheets
      @invalid_timesheets = @employee_timesheets.no_timeout
      if @invalid_timesheets.present?
        render :template => 'timesheets/manual_timeout'
      else
        render :template => 'timesheets/index'
      end

    else
      redirect_to signin_url
    end
  end

  def timein
    begin
      redirect_to :timesheets if Timesheet.time_in!(current_user)
    rescue NoTimeoutError
      @invalid_timesheets = current_user.timesheets.latest.where("time_out is null")
      render :template => 'timesheets/manual_timeout'
    end
  end

  def timeout
    begin
      redirect_to :timesheets if Timesheet.time_out!(current_user)
    rescue NoTimeinError
      @invalid_timesheet = current_user.timesheets.new(:date => Time.now.utc)
      render :template => 'timesheets/manual_timein'
    end
  end

  def manual_timein
    timesheet = current_user.timesheets.new(:time_out => Time.now.utc)
    timesheet.manual_update(params[:timein]) if params[:timein]
    redirect_to :timesheets
  end

  def manual_timeout
    timesheet = Timesheet.find(params[:id])
    timesheet.manual_update(params[:timeout]) if params[:timeout]
    redirect_to :timesheets
  end
end
