class HolidaysController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!
  before_filter :set_location
  before_filter :get_employee

  def index
    if @employee.is_hr?
      default_month_range(params[:searchRange])
      js_params[:range] = [@range.first, @range.last]
      js_params[:holidays] = attrs Holiday.asc.within(@range)
      set_location('hrmodule')
      respond_js_params
    else
      render_404
    end
  end

  def create
    holiday = Holiday.new(params[:holiday])
    holiday.branches = Branch.find_all_by_id(params[:branch_ids])
    errors = holiday.errors unless holiday.save

    js_params[:errors]  = { error: errors.full_messages.join('<br>') } if errors
    js_params[:success] = { success: "Holiday was created successfully." } unless errors
    respond_js_params
  end

  def update
    holiday = Holiday.find_by_id(params[:id])
    branches = Branch.find_all_by_id(params[:branch_ids])
    errors = holiday.errors unless holiday.update_attrs_with_branches(params[:holiday], branches)

    js_params[:errors]  = { error: holiday.errors.full_messages.join('<br>') } if errors
    js_params[:success] = { success: "Holiday was updated successfully." } unless errors
    respond_js_params
  end

  def destroy
    holiday = Holiday.find_by_id(params[:id])
    errors = holiday.errors unless holiday.destroy

    js_params[:success]  = { success: "Holiday was deleted successfully." } unless errors
    js_params[:errors] = { error: holiday.errors.full_messages.join('<br>') } if errors
    respond_js_params
  end

  private
  def attrs(holidays)
    holidays.map do |holiday|
      holiday.attributes.merge({
        :branches => holiday.branches.map(&:code).join(', '),
        :cancelable => holiday.is_cancelable?,
        :editable => holiday.is_editable?
      })
    end
  end

  def default_month_range(date=nil)
    date = Time.parse(date) if date
    date ||= Time.now
    @range = Range.new(date.beginning_of_month, date.end_of_month)
  end

  def get_employee
    @employee = current_user.employee
  end

  def respond_js_params
    respond_to do |format|
      format.html { render :template => "layouts/application" }
      format.json { render :json => js_params.to_json }
    end
  end

  def set_location(location = 'leaves')
    js_params[:current_location] = location
  end
end
