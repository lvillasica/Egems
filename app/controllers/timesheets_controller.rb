class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :active_timesheet, :only => [:index]
  before_filter :invalid_timesheet_prev, :only => [:index, :timesheets_nav]

  def index
    if user_signed_in?
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
    rescue Timesheet::NoTimeoutError
      @invalid_timesheets = current_user.timesheets.latest.no_timeout
      flash[:alert] = error_message(:no_timeout)
      render :template => 'timesheets/manual_timeout'
    end
  end

  def timeout
    begin
      redirect_to :timesheets if Timesheet.time_out!(current_user)
    rescue Timesheet::NoTimeinError
      @invalid_timesheet = current_user.timesheets.new(:date => Time.now.beginning_of_day)
      flash[:alert] = error_message(:no_timein)
      render :template => 'timesheets/manual_timein'
    end
  end

  def manual_timein
    timesheet = current_user.timesheets.new(:time_out => Time.now)
    timesheet.manual_update(params[:timein]) if params[:timein]
    redirect_to :timesheets
  end

  def manual_timeout
    timesheet = Timesheet.find(params[:id])
    timesheet.manual_update(params[:timeout]) if params[:timeout]
    redirect_to :timesheets
  end
  
  def timesheets_nav
    @active_time = (params[:time].blank? ? Time.now.beginning_of_day : Time.parse(params[:time]))
    active_timesheet(@active_time)
    render :action => :index
  end
  
private
  def active_timesheet(active_time = Time.now.beginning_of_day)
    @employee_timesheets_active = current_user.timesheets.latest(active_time)
  end
  
  def invalid_timesheet_prev
    @invalid_timesheets = current_user.timesheets.previous.no_timeout
  end
  
end
