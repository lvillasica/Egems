class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee, :except => [:manual_timeout, :timesheets_nav]
  before_filter :active_timesheet, :only => [:index]
  before_filter :invalid_timesheet_prev, :only => [:index, :timesheets_nav]

  def index
    if user_signed_in?
      template = (@invalid_timesheets.present? ? 'manual_timeout' : 'index')
      render :template => "timesheets/#{template}"
    else
      redirect_to signin_url
    end
  end

  def timein
    begin
      redirect_to :timesheets if Timesheet.time_in!(@employee)
    rescue Timesheet::NoTimeoutError
      @invalid_timesheets = @employee.timesheets.latest.no_timeout
      @force = true
      flash_message(:alert, :no_timeout)
      render :template => 'timesheets/manual_timeout'
    end
  end

  def timeout
    begin
      redirect_to :timesheets if Timesheet.time_out!(@employee)
    rescue Timesheet::NoTimeinError
      @invalid_timesheet = @employee.timesheets.new(:date => Time.now.beginning_of_day)
      flash_message(:alert, :no_timein)
      render :template => 'timesheets/manual_timein'
    end
  end

  def manual_timein
    @timesheet = @employee.timesheets.new(:time_out => Time.now)
    save_manual_timeentry('timein', params[:timein])
  end

  def manual_timeout
    @timesheet = Timesheet.find_by_id(params[:id])
    save_manual_timeentry('timeout', params[:timeout], params[:forced])
  end

  def timesheets_nav
    @active_time = (params[:time].blank? ? Time.now.beginning_of_day : Time.parse(params[:time]))
    active_timesheet(@active_time)
    render :action => :index
  end

  def timesheets_nav_week
    time = Time.parse(params[:time])
    @active_time = Range.new(time.monday, time.sunday)
    @employee_timesheets_active = @employee.timesheets.within(@active_time).asc
                                           .group_by(&:shift_schedule_detail_id)
    render :template => 'timesheets/weekly'
  end

private
  def get_employee
    @employee = current_user.employee
  end

  def active_timesheet(active_time = Time.now.beginning_of_day)
    @employee ||= get_employee
    @employee_timesheets_active = @employee.timesheets.latest(active_time)
  end

  def invalid_timesheet_prev
    @employee ||= get_employee
    @invalid_timesheets = @employee.timesheets.previous.no_timeout
    if session[:invalid_timein_after_signin] && @invalid_timesheets.blank?
      @invalid_timesheets = @employee.timesheets.latest.no_timeout
      @force = true
    end
    session.delete(:invalid_timein_after_signin)
  end

  # TODO: Refactor
  def save_manual_timeentry(type, attrs, forced=nil)
    @employee ||= get_employee
    if @timesheet.manual_update(attrs, forced)
      redirect_to :timesheets
    else
      errors = @timesheet.errors
      flash_message(:alert, errors.full_messages) if errors.any?
      if type.eql?('timein')
        date = Time.now.beginning_of_day
        @invalid_timesheet = @employee.timesheets.new(:date => date)
      else
        @invalid_timesheets = @employee.timesheets.latest.no_timeout
        @force = forced
      end
      render :template => "timesheets/manual_#{type}"
    end
  end

end
