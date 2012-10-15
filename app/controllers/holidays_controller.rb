class HolidaysController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!
  before_filter :get_employee

  def index
    if @employee.is_hr?
      holidays = attrs Holiday.asc.within(default_date_range)
      respond_to do |format|
        format.html { render :template => "layouts/application" }
        format.json { render :json => holidays.to_json }
      end
    else
      render_404
    end
  end

  def create
    holiday = Holiday.new(params[:holiday])
    holiday.branches = Branch.find_all_by_id(params[:branch_ids])
    holiday.save

    js_params[:errors]   = { error: holiday.errors.full_messages.join('<br>') } if holiday.errors.present?
    js_params[:success]  = { success: "Successfully added holiday." } if holiday.errors.empty?
    js_params[:holidays] = attrs Holiday.asc.within(default_date_range)

    respond_to do |format|
      format.html { render :template => "layouts/applications" }
      format.json { render :json => js_params.to_json }
    end
  end

  private
  def attrs(holidays)
    holidays.map do |holiday|
      holiday.attributes.merge({
        :branches => holiday.branches.map(&:code).join(', '),
        :cancelable => holiday.is_cancelable?
      })
    end
  end

  def default_date_range
    today = Time.now
    range = Range.new(today.beginning_of_year.utc, today.end_of_year.utc)
  end

  def get_employee
    @employee = current_user.employee
  end
end
