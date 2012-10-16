class EmployeeMappingsController < ApplicationController
  respond_to :json
  
  before_filter :authenticate_user!
  before_filter :get_employees, :only => [:index]
  before_filter :get_employee
  before_filter :authenticate_hr!
  
  def index
    js_params[:employees] = @employees
    respond_with_json
  end
  
  def show
    render_404 unless @emp = Employee.find_by_id(params[:id])
    js_params[:supervisors] = @emp.mapped_supervisors.with_names(:approver)
    js_params[:project_managers] = @emp.mapped_project_managers.with_names(:approver)
    js_params[:members] = @emp.employee_mappings_as_approver.with_names(:member)
    respond_with_json
  end
  
  def create
    @approver = Employee.find_by_id(params[:employee_mapping].delete(:approver_id))
    @employee_mapping = @approver.employee_mappings_as_approver.build(params[:employee_mapping])
    if @employee_mapping.save
      flash_message(:success, "Mapping was successfully created.")
      flash_message(:warning, @employee_mapping.errors.full_messages) if @employee_mapping.errors.any?
    else
      flash_message(:error, @employee_mapping.errors.full_messages) if @employee_mapping.errors.any?
    end
    js_params[:employee_mapping] = @employee_mapping
    set_flash
    respond_with_json
  end
  
  def update
    @approver = Employee.find_by_id(params[:employee_mapping].delete(:approver_id))
    @employee_mapping = @approver.employee_mappings_as_approver.find_by_id(params[:id])
    if @employee_mapping.update_if_changed(params[:employee_mapping])
      flash_message(:success, "Mapping was successfully updated.")
      flash_message(:warning, @employee_mapping.errors.full_messages) if @employee_mapping.errors.any?
    else
      flash_message(:error, @employee_mapping.errors.full_messages) if @employee_mapping.errors.any?
    end
    js_params[:employee_mapping] = @employee_mapping
    set_flash
    respond_with_json
  end
  
  def destroy
    @approver = Employee.find_by_id(params[:employee_mapping][:approver_id])
    @employee_mapping = @approver.employee_mappings_as_approver.find_by_id(params[:id])
    @employee_mapping.destroy
    flash_message(:success, "Removed mapping.")
    set_flash
    respond_with_json
  end
  
private
  def authenticate_hr!
    render_404 unless @employee.is_hr? or @employee.is_supervisor_hr?
  end
  
  def get_employees
    @employees = if ['Supervisor/TL', 'Project Manager'].include?(params[:type])
      Employee.with_supervisory.select([:id, :full_name]).order(:full_name)
    else
      Employee.select([:id, :full_name]).order(:full_name)
    end
  end
  
  def get_employee
    @employee = current_user.employee
    render_404 unless @employee
  end
  
  def set_flash
    js_params[:flash_messages] = flash.to_hash
    flash.discard # make sure error msgs don't show on other page
  end

  def respond_with_json
    @data = js_params
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end

end
