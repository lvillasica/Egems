class OvertimesController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, except: [:index]
  before_filter :get_employee

  def index
    @overtimes = @employee.overtimes
    js_params[:overtimes] = @overtimes
    respond_with_json
  end

  def new
    @overtime = @employee.overtimes.new(params[:overtime])
    js_params[:overtime] = @overtime
    respond_with_json
  end

  def create
    @overtime = @employee.overtimes.new(params[:overtime])
    if @overtime.save
      flash_message(:notice, "Overtime dated on #{ view_context.format_date @overtime.date_of_overtime }
                              with a duration of #{ @overtime.duration } was
                              successfully created.")
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

  def update
    #
  end

private
  def get_employee
    @employee = current_user.employee
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

  def overtime_attributes
    @overtimes.each do |ovr|
      js_params[:overtime] = ovr.attributes.merge({
        :responders => ovr.get_responders
        })
    end
  end
end

