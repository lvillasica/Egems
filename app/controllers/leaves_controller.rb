class LeavesController < ApplicationController
  respond_to :json
  
  before_filter :authenticate_user!, :except => [:index]
  before_filter :get_employee
  
  def index
    @leaves = @employee.leaves.active.order_by_id
    init_data
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end
  
private
  def get_employee
    @employee = current_user.employee
  end
  
  def init_data
    js_params[:leaves] = leaves_with_pending_and_balance
    @data = js_params
  end
  
  def leaves_with_pending_and_balance
    @leaves.map do | l |
      l.attributes.merge({
        :total_pending => l.total_pending,
        :remaining_balance => l.remaining_balance
      })
    end
  end

end
