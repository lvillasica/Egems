class LeavesController < ApplicationController
  respond_to :json
  
  before_filter :authenticate_user!, :except => [:index]
  before_filter :set_location
  before_filter :get_employee
  before_filter :authenticate_hr!, :only => [:crediting, :grant]
  before_filter :get_qualified_for_leaves, :only => [:grant]
  
  def index
    @leaves = @employee.leaves.active.order_by_id
    init_data
    respond_to do | format |
      format.html { render :template => "layouts/application" }
      format.json { render :json => @data.to_json }
    end
  end
  
  def create
    # TODO
  end
  
  def update
    # TODO
  end
  
  def destroy
    # TODO
  end
  
  def crediting
    current_year = Time.now.year + 1
    js_params[:years] = (current_year ... (current_year + 10))
    respond_with_json
  end
  
  def grant
    if @qualified_for_leaves.any?
      @qualified_for_leaves.each do |emp|
        emp.grant_major_leaves!(@year)
      end
      flash_message(:success, 'VL / SL / AWOP granted to all qualified employees.')
    else
      flash_message(:info, 'VL / SL / AWOP already granted to all qualified employees.')
    end
    set_flash
    respond_with_json
  end
  
private
  def authenticate_hr!
    set_location('hrmodule')
    render_404 unless @employee.is_hr? or @employee.is_supervisor_hr?
  end
  
  def get_employee
    @employee = current_user.employee
  end
  
  def get_qualified_for_leaves
    @year = params[:year] ? params[:year].to_i : Time.now.year
    @qualified_for_leaves = if params[:qualified_ids]
      Employee.find_all_by_id(params[:qualified_ids]).select do |e|
        e.is_qualified_for_leaves?(@year) and !e.granted_with_major_leaves?(@year)
      end
    else
      Employee.all_qualified_for_leaves(@year).select do |e|
        !e.granted_with_major_leaves?(@year)
      end
    end
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
  
  def set_location(location = 'leaves')
    js_params[:current_location] = location
  end

end
