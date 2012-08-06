class LeaveDetailsController < ApplicationController
  respond_to :json
  
  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee
  before_filter :get_leave
  before_filter :set_js_params, :only => [:new]
  
  def index
    @leave_details = @leave.leave_details.active.asc if @leave
    init_data
    respond_with_json
  end
  
  def new
    @leave_detail = @employee.leave_details.new
    leave_detail_attrs
    respond_with_json
  end
  
  def create
    @leave_detail = @employee.leave_details.new(params[:leave_detail])
    if @leave_detail.save
      flash_message(:notice, "#{@leave_detail.leave_type} dated on #{@leave_detail.dated_on} was successfully created.")
      flash_message(:warning, @leave_detail.errors.full_messages) if @leave_detail.errors.any?
      js_params[:total_pending] = @employee.total_pending_leaves
    else
      flash_message(:error, @leave_detail.errors.full_messages) if @leave_detail.errors.any?
    end
    leave_detail_attrs
    respond_with_json
  end
  
private
  def get_employee
    @employee = current_user.employee
  end
  
  def get_leave
    @leave = @employee.leaves.type(params['leave_type']).first ||
             @employee.leaves.first
  end
  
  def set_js_params
    leave_range = (@leave.date_from .. @leave.date_to)
    js_params[:day_offs] = @employee.day_offs_within(leave_range)
    js_params[:holidays] = @employee.holidays_within(leave_range)
  end
  
  def init_data
    js_params[:leave_details] = leave_details_with_responders
    @data = js_params
  end
  
  def leave_details_with_responders
    @leave_details.map do | ld |
      ld.attributes.merge({:get_responders => ld.get_responders})
    end
  end
  
  def leave_detail_attrs
    leave_range = (@leave.date_from .. @leave.date_to)
    leaves_allocations = {}
    @employee.leaves.each do |leave|
      leaves_allocations[leave.leave_type] = leave.leaves_allocated
      leaves_allocations["Emergency Leave"] = leave.leaves_allocated if leave.leave_type == "Vacation Leave"     
    end

    js_params[:leave_detail] = @leave_detail.attributes.merge({
      :leave_start_date => @leave.date_from,
      :leave_end_date => @leave.date_to,
      :employee_leaves => leaves_allocations,
      :day_offs => @employee.day_offs_within(leave_range),
      :holidays => @employee.holidays_within(leave_range)
    })
    js_params[:flash_messages] = flash.to_hash
    flash.discard # make sure error msgs don't show on other page
    @data = js_params
  end
  
  def respond_with_json
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end
  
end
