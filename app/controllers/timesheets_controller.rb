class TimesheetsController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee, :except => [:manual_timeout, :timesheets_nav]
  before_filter :get_active_timesheets, :only => [:index]
  before_filter :get_invalid_timesheet, :only => [:index]

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
                                           .unemptize(@employee, @active_time) do |s|
                                              s.shift_schedule_detail.day_of_week
                                            end
    respond_with_json
  end

  def new_leave
    if request.get?
      if (leaves = @employee.leaves.active.from_timesheets).present?
        leave = leaves.first
        leaves_of_type = leaves.type(leave.leave_type)
        leave_date = (params[:date] || Date.today).to_time

        leave_start = leaves_of_type.minimum(:date_from)
        leave_end = leaves_of_type.maximum(:date_to)
        leave_range = Range.new(leave_start, leave_end)

        leaves_allocations = {}
        leaves.each do |leave|
          leaves_allocations[leave.leave_type] = leave.leaves_allocated
          leaves_allocations["Emergency Leave"] = leave.leaves_allocated if leave.leave_type == "Vacation Leave"
        end

        leave_detail = @employee.leave_details.new({ leave_type: leave.leave_type })
        js_params[:leave_detail] = leave_detail.attributes.merge({
          :leave_start_date => leave_start,
          :leave_end_date => leave_end,
          :end_date => leave_date,
          :employee_leaves => leaves_allocations,
          :day_offs => @employee.day_offs_within(leave_range),
          :holidays => @employee.holidays_within(leave_range)
        })
      else
        js_params[:flash_messages] = { error: 'No allocated leaves.' }
      end
      respond_with_json
    end
  end

private
  def get_employee
    @employee = current_user.employee
  end

  def get_active_timesheets(active_time = Time.now.beginning_of_day)
    @employee ||= get_employee
    @employee_timesheets_active = @employee.timesheets.by_date(active_time).asc
                                           .unemptize(@employee, active_time)
  end

  def get_invalid_timesheet
    @employee ||= get_employee
    if session[:invalid_timein_after_signin]
      @invalid_timesheet = @employee.timesheets.asc.no_timeout.first
      js_params[:error] = ['error', flash_message(:alert, :no_timeout)]
    end
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
    return nil if @employee_timesheets_active.nil? or @employee_timesheets_active.empty?
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
