class OvertimesController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, except: [:index]
  before_filter :get_employee
  before_filter :get_overtime, :only => [:edit, :update, :cancel]

  def index
    @overtimes = @employee.overtimes
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
      js_params[:overtime] = @overtime
      flash_message(:notice, "Overtime dated on #{ view_context.format_date @overtime.date_of_overtime }
                              with a duration of #{ view_context.format_in_hours @overtime.duration } was
                              successfully updated.")
      flash_message(:warning, @overtime.errors.full_messages) if @overtime.errors.any?
    else
      flash_message(:error, @overtime.errors.full_messages) if @overtime.errors.any?
    end
    
    set_flash
    respond_with_json
  end

  def cancel
    #
  end

  def requests
    js_params[:pending] = attrs(@employee.for_response_overtimes.pending)
    if @employee.is_supervisor?
      respond_with_json
    else
      render_404
    end
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
        :responders => overtime.get_responders.map(&:full_name)
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
end
