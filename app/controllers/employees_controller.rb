class EmployeesController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!
  #before_filter :get_employee
  
  def index
    @employees = Employee.all
    js_params[:employees] = @employees
    respond_with_json
  end
  
  def for_leave_crediting
    @year = Time.now.year
    @for_leave_crediting = Employee.regularized_on_year(@year).asc_name
                                   .all_qualified_for_leaves(@year)
    js_params[:for_leave_crediting] = @for_leave_crediting.select do |e|
      !e.granted_with_major_leaves?(@year)
    end
    respond_with_json
  end
  
  def leaves_credited
    @year = params[:year].blank? ? Time.now.year : params[:year].to_i
    js_params[:granted_employees] = Employee.not_resigned.asc_name.select do |e|
      e.granted_with_major_leaves?(@year)
    end
    respond_with_json
  end

private
  def get_employee
    @employee = current_user.employee
    render_404 unless @employee
  end

  def respond_with_json
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => js_params.to_json }
    end
  end
end
