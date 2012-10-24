class OvertimesController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, except: [:index]
  before_filter :set_location
  before_filter :get_employee
  before_filter :get_overtime, :only => [:edit, :update, :cancel]

  def index
    @overtimes = @employee.overtimes.asc_by_overtime_date
    js_params[:overtimes] = overtimes_with_more_attrs
    respond_with_json
  end

  def new
    if request.xhr?
      @overtime = @employee.overtimes.new(params[:overtime])
      js_params[:overtime] = overtime_with_max_duration
      respond_with_json
    else
      redirect_to :timesheets
    end
  end

  def create
    @overtime = @employee.overtimes.new(params[:overtime])
    if @overtime.save
      flash_message(:notice, "Overtime dated on #{ view_context.format_date @overtime.date_of_overtime }
                              with a duration of #{ view_context.format_in_hours @overtime.duration } was
                              successfully created.")
      flash_message(:warning, @overtime.errors.full_messages) if @overtime.errors.any?
    else
      flash_message(:error, @overtime.errors.full_messages) if @overtime.errors.any?
    end
    set_flash
    respond_with_json
  end

  def edit
    if request.xhr?
      js_params[:overtime] = overtime_with_max_duration
      respond_with_json
    else
      redirect_to :timesheets
    end
  end

  def update
    if @overtime.update_if_changed(params[:overtime])
      flash_message(:notice, "Overtime dated on #{ view_context.format_date @overtime.date_of_overtime }
                              with a duration of #{ view_context.format_in_hours @overtime.duration } was
                              successfully updated.")
      flash_message(:warning, @overtime.errors.full_messages) if @overtime.errors.any?
    else
      flash_message(:error, @overtime.errors.full_messages) if @overtime.errors.any?
    end
    js_params[:overtime] = @overtime
    set_flash
    respond_with_json
  end

  def cancel
    if @overtime.cancel!
      flash_message(:notice, "Overtime dated on #{ view_context.format_date @overtime.date_of_overtime }
                              with a duration of #{ view_context.format_in_hours @overtime.duration } was
                              successfully canceled.")
      flash_message(:warning, @overtime.errors.full_messages) if @overtime.errors.any?
    else
      flash_message(:error, @overtime.errors.full_messages) if @overtime.errors.any?
    end
    js_params[:overtime] = @overtime
    set_flash
    respond_with_json
  end

  def requests
    js_params[:pending] = attrs(@employee.for_response_overtimes.pending.asc)
    if @employee.is_supervisor?
      respond_with_json
    else
      render_404
    end
  end

  def bulk_approve
    errors = Hash.new
    approved_ots = params[:approved_ots]
    actions = OvertimeAction.find_all_by_id(approved_ots.keys)
    actions.each do |action|
      action.approved_duration = approved_ots["#{action.id}"].to_i
      overtime = action.overtime
      unless action.approve!(@employee)
        msg = "Can't approve request dated #{ view_context.format_date overtime.date_of_overtime } of #{overtime.employee.full_name}"
        errors[msg] = action.errors.full_messages
      end
    end
    js_params[:success] = { success: "Overtime/s successfully approved." } if errors.empty?
    js_params[:errors] = errors unless errors.empty?
    requests
  end

  def bulk_reject
    errors = Hash.new
    actions = OvertimeAction.find_all_by_id(params[:rejected_ids])
    actions.each do |action|
      overtime = action.overtime
      unless action.reject!(@employee)
        msg = "Can't reject request dated <#{overtime.date_of_overtime}> of #{overtime.employee.full_name}"
        errors[msg] = action.errors.full_messages
      end
    end
    js_params[:success] = { success: "Overtime/s successfully rejected." } if errors.empty?
    js_params[:errors] = errors unless errors.empty?
    requests
  end

private
  def get_employee
    @employee = current_user.employee
  end

  def get_overtime
    @overtime = @employee.overtimes.find_by_id(params[:id])
    if @overtime.nil?
      js_params[:error_response] = 'Record not found.'
      respond_with_json
    end
  end

  def set_flash
    js_params[:flash_messages] = flash.to_hash
    flash.discard # make sure error msgs don't show on other page
  end

  def respond_with_json
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => js_params.to_json }
    end
  end

  def overtime_with_max_duration
    @overtime.attributes.merge({ :max_duration => @overtime.max_duration })
  end

  def overtimes_with_more_attrs
    # add more attrs for each overtime here...
    @overtimes.map do |overtime|
      overtime.attributes.merge({
        :responders => overtime.get_responders.map(&:full_name),
        :response_date => overtime.response_date
      })
    end
  end

  def attrs(overtime_requests)
    overtime_requests.map do |action|
      overtime = action.overtime
      action.attributes.merge({
        :employee_name => overtime.employee.full_name,
        :date_filed => overtime.date_filed.to_date,
        :date_of_overtime => overtime.date_of_overtime,
        :duration => overtime.duration,
        :work_details => overtime.work_details
      })
    end
  end
  
  def set_location(location = 'overtimes')
    js_params[:current_location] = location
  end
end
