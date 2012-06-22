class LeaveDetailsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee
  before_filter :get_leave, :only => [:index]
  
  def index
    redirect_to timesheets_path if params[:leave_type].blank? || @leave.nil?
    @leave_details = @employee.leave_details.type(params[:leave_type])
  end
  
  def new
    redirect_to timesheets_path if @employee.leaves.empty?
    @leave_detail = @employee.leave_details.new
  end
  
  def create
    @leave_detail = @employee.leave_details.new(params[:leave_detail])
    if @leave_detail.save
      redirect_to leave_details_path(:leave_type => params[:leave_detail][:leave_type])
    else
      render :action => "new"
    end
  end
  
private
  def get_employee
    @employee = current_user.employee
  end
  
  def get_leave
    @leave = @employee.leaves.type(params[:leave_type]).first
  end
  
end
