class OvertimesController < ApplicationController
  respond_to :json

  before_filter :get_employee
  before_filter :authenticate_user!, except: [:index]

  def index
    @overtime = @employee.overtimes
    init_data
    respond_with_json
  end

  def new
    @employee = current_user.employee
    @overtime = @employee.overtimes.new()
    respond_with_json
  end

  def create
    @employee = current_user.employee
    @overtime = @employee.overtimes.new(params[:overtime])
    if @overtime.save
      flash_message(:notice, "Overtime dated on #{@overtime.date_of_overtime} with a duration of #{@overtime.duration} was successfully created.")
      flash_message(:warning, @overtime.errors.full_messages) if @overtime.errors.any?
      js_params[:overtime_pending] = @employee.total_pending_overtimes
    else
      flash_message(:error, @overtime.errors.full_messages) if @overtime.errors.any?
    end
    respond_with_json
  end

  def cancel
    # 
  end

  def update
    # 
  end

  private
  def get_employee
    @employee =  current_user.employee
  end

  def init_data
    js_params[:overtime] = @employee.overtimes
    @data = js_params
  end

  def respond_with_json
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end

  def overtime_attributes
    @overtime.each do |ovr|
      js_params[:overtime] = ovr.attributes.merge({
        :responders => ovr.get_responders
        })
    end
      js_params[:flash_messages] = flash.to_hash
    flash.discard # make sure error msgs don't show on other page
    @data = js_params
  end


end

