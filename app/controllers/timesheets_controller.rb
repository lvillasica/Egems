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

  def manual_time_entry
    @timesheet = @employee.timesheets.new
    begin
      if @timesheet.manual_entry(params)
        get_active_timesheets(@timesheet.date.localtime)
      else
        set_flash
      end
    rescue Timesheet::NoTimeoutError
      time = @timesheet.validate_time_attrs(params[:timein])
      invalid_timesheets = @employee.timesheets.latest(time).no_timeout +
                           @employee.timesheets.previous(time).no_timeout
      @invalid_timesheet = invalid_timesheets.first
      js_params[:error] = ['error', flash_message(:alert, :no_timeout)]
    end
    respond_with_json
  end
  
  def edit_manual_entry
    @timesheet = @employee.timesheets.find_by_id(params[:id])
    if @timesheet.update_manual_entry(params)
      js_params[:time_entry] = @timesheet
      set_flash(:info)
    else
      set_flash
    end
    respond_to do |format|
      format.html { render :template => 'layouts/application' }
      format.json { render :json => js_params.to_json }
    end
  end

  def manual_timesheet_requests
    if @employee.is_supervisor?
      js_params[:pending] = attrs Timesheet.response_by(@employee).pending_manual
      respond_to do |format|
        format.html { render :template => 'layouts/application' }
        format.json { render :json => js_params.to_json }
      end
    else
      render_404
    end
  end

  def bulk_approve
    errors = Hash.new
    timesheets = Timesheet.find_all_by_id(params[:approved_ids])
    timesheets.each do |timesheet|
      unless timesheet.approve!(@employee)
        msg = "Can't approve time entry of #{timesheet.employee.full_name}"
        errors[msg] = timesheet.errors.full_messages
      end
    end

    js_params[:success] = { success: "Timesheet/s successfully approved." } if errors.empty?
    js_params[:errors] = errors if errors.present?
    manual_timesheet_requests
  end

  def bulk_reject
    errors = Hash.new
    timesheets = Timesheet.find_all_by_id(params[:rejected_ids])
    timesheets.each do |timesheet|
      unless timesheet.reject!(@employee)
        msg = "Can't reject time entry of #{timesheet.employee.full_name}"
        errors[msg] = timesheet.errors.full_messages
      end
    end

    js_params[:success] = { success: "Timesheet/s successfully rejected." } if errors.empty?
    js_params[:errors] = errors if errors.present?
    manual_timesheet_requests
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
        leave_date = (params[:date] || Date.today).to_time rescue Date.today.to_time

        leave_start = leaves_of_type.minimum(:date_from)
        leave_end = leaves_of_type.maximum(:date_to)
        leave_range = Range.new(leave_start, leave_end)

        leaves_allocations = {}
        leaves.each do |leave|
          leaves_allocations[leave.leave_type] = leave.leaves_allocated
        end
        el = @employee.leaves.type("Emergency Leave").first
        leaves_allocations["Emergency Leave"] = el.leaves_allocated if el

        leave_detail = @employee.leave_details.new({ leave_type: leave.leave_type })
        js_params[:leave_detail] = leave_detail.attributes.merge({
          :leave_start_date => leave_start,
          :leave_end_date => leave_end,
          :leave_date => leave_date,
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
    js_params[:overtime] = @employee.overtimes
                                    .find_by_date_of_overtime(active_time.utc)
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
        t.attributes.merge({
          :time_in => t.time_in_without_adjustment,
          :is_editable => t.is_editable?
        })
      end
    end
    timesheets
  end

  def attrs(timesheets)
    timesheets.map do |timesheet|
      timesheet.attributes.merge({
        :employee_name => timesheet.employee.full_name,
        :time_in => timesheet.time_in_without_adjustment })
    end
  end
  
  def set_flash(type = :error)
    flash_message(type, @timesheet.errors.full_messages) if @timesheet.errors.any?
    js_params[:flash_messages] = flash.to_hash
    flash.discard
  end

end
