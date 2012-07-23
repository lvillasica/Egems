class TimesheetsController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee, :except => [:manual_timeout, :timesheets_nav]
  before_filter :get_active_timesheets, :only => [:index]
  before_filter :invalid_timesheet_prev, :only => [:index, :timesheets_nav]

  def index
    if user_signed_in?
      respond_with_json
    else
      redirect_to signin_url
    end
  end

  def timein
    begin
      Timesheet.time_in!(@employee)
    rescue Timesheet::NoTimeoutError
      invalid_timesheets = @employee.timesheets.latest.no_timeout +
                           @employee.timesheets.previous.no_timeout
      @invalid_timesheet = invalid_timesheets.first
      js_params[:error] = ['error', flash_message(:alert, :no_timeout)]
    end
    get_active_timesheets
    respond_with_json
  end

  def timeout
    begin
      Timesheet.time_out!(@employee)
    rescue Timesheet::NoTimeinError
      @invalid_timesheet = @employee.timesheets.new(:date => Time.now.beginning_of_day)
      js_params[:error] = ['error', flash_message(:alert, :no_timein)]
      js_params[:shift] = @employee.shift_schedule.details[Time.now.wday].valid_time_in.first
      js_params[:lastTimesheet] = @employee.timesheets.desc.first
    end
    get_active_timesheets
    respond_with_json
  end

  def manual_timein
    @timesheet = @employee.timesheets.new(:time_out => Time.now)
    save_manual_timeentry('timein', params[:timein])
  end

  def manual_timeout
    @timesheet = Timesheet.find_by_id(params[:id])
    save_manual_timeentry('timeout', params[:timeout])
  end

  def timesheets_nav
    @active_time = (params['time'].blank? ? Time.now.beginning_of_day : Time.parse(params['time']))
    get_active_timesheets(@active_time)
    respond_with_json
  end

  def timesheets_nav_week
    time = Time.parse(params['time'])
    @active_time = [time.monday, time.sunday]
    @employee_timesheets_active = @employee.timesheets.within(@active_time).asc
                                           .group_by { |s| s.shift_schedule_detail.day_of_week }
    respond_with_json
  end

private
  def get_employee
    @employee = current_user.employee
  end

  def get_active_timesheets(active_time = Time.now.beginning_of_day)
    @employee ||= get_employee
    @employee_timesheets_active = @employee.timesheets.by_date(active_time).asc
  end

  def invalid_timesheet_prev
    @employee ||= get_employee
    if session[:invalid_timein_after_signin]
      @invalid_timesheet = @employee.timesheets.asc.no_timeout.first
    end
    session.delete(:invalid_timein_after_signin)
  end

  # TODO: Refactor
  def save_manual_timeentry(type, attrs)
    @employee ||= get_employee
    unless @timesheet.manual_update(attrs)
      if (errors = @timesheet.errors).any?
        js_params[:error] = ['error', flash_message(:alert, errors.full_messages)]
      end

      if type.eql?('timein')
        date = Time.now.beginning_of_day
        @invalid_timesheet = @employee.timesheets.new(:date => date)
      else
        invalid_timesheets = @employee.timesheets.previous.no_timeout +
                             @employee.timesheets.latest.no_timeout
        @invalid_timesheet = invalid_timesheets.first
      end
    end
    get_active_timesheets
    respond_with_json
  end

  def respond_with_json
    js_params[:invalid_timesheet] = @invalid_timesheet
    js_params[:employee_timesheets_active] = with_original_time_in
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => js_params.to_json }
    end
  end

  def with_original_time_in
    return nil if @employee_timesheets_active.nil?
    if @employee_timesheets_active.is_a?(Hash)
      timesheets = @employee_timesheets_active.map do |k, timesheets|
        timesheets.map do |t|
          t.attributes.merge({ :time_in => t.time_in_without_adjustment })
        end
      end
    else
      timesheets = @employee_timesheets_active.map do |t|
        t.attributes.merge({ :time_in => t.time_in_without_adjustment })
      end
    end
    timesheets
  end

end
