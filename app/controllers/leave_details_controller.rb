class LeaveDetailsController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee
  before_filter :get_leave_detail, :only => [:edit, :update, :cancel]
  before_filter :get_leave
  before_filter :set_js_params, :only => [:new]

  def index
    @leave_details = @leave.leave_details.active.asc if @leave
    init_data
    request.xhr? ? respond_with_json : redirect_to(:timesheets)
  end

  def new
    @leave_detail = @employee.leave_details.new({ :leave_type => @leave.leave_type })
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
  
  def edit
    @leaves = [@leave_detail.leave]
    leave_detail_attrs
    respond_with_json
  end
  
  def update
    @leaves = [@leave_detail.leave]
    params[:leave_detail][:leave_type] = @leave_detail.leave_type
    if @leave_detail.update_attributes(params[:leave_detail])
      flash_message(:notice, "#{@leave_detail.leave_type} dated on #{@leave_detail.dated_on} was successfully updated.")
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
  
  def get_leave_detail
    @leave_detail = @employee.leave_details.find_by_id(params[:id])
  end

  def get_leave
    if (@leaves = @employee.leaves).present?
      if params[:leave_type]
        @leaves_of_type = @leaves.type(params[:leave_type])
        @leaves_of_type = @leaves.type('Vacation Leave') if params[:leave_type] == 'Emergency Leave'
        @leave = @leaves_of_type.where("? between date_from and date_to", Time.now).first ||
                 @leaves_of_type.first || @employee.leaves.first
      else
        @leave = (@leave_detail.leave rescue nil) || @leaves.first
        @leaves_of_type = @leaves.type(@leave.leave_type)
      end
    else
      js_params[:flash_messages] = { error: 'No allocated leaves.' }
      @data = js_params
      respond_with_json
    end
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
    leave_start = @leaves_of_type.minimum(:date_from)
    leave_end = @leaves_of_type.maximum(:date_to)
    leave_range = Range.new(leave_start, leave_end)
    leaves_allocations = {}
    @leaves.each do |leave|
      leaves_allocations[leave.leave_type] = leave.leaves_allocated
      leaves_allocations["Emergency Leave"] = leave.leaves_allocated if leave.leave_type == "Vacation Leave"
    end

    js_params[:leave_detail] = @leave_detail.attributes.merge({
      :leave_start_date => leave_start,
      :leave_end_date => leave_end,
      :end_date => @leave_detail.end_date,
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
