class LeavesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee
  
  def index
    @leaves = @employee.leaves.current
  end
  
private
  def get_employee
    @employee = current_user.employee
  end

end
