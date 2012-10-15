class EmployeesController < ApplicationController
  respond_to :json

  before_filter :authenticate_user!
  before_filter :get_employee
  
  def index
    @employees = Employee.all
    js_params[:employees] = @employees
    respond_with_json
  end

private
  def get_employee
    @employee = current_user.employee
    render_404 unless @employee
  end

  def respond_with_json
    @data = js_params
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end
end
