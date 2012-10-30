class ShiftSchedulesController < ApplicationController

  respond_to :json
  before_filter :authenticate_user!
  before_filter :get_shift, :only => [:details, :update, :destroy]

  def index
    #don't store data in data-container
    @data_ = shift_attrs ShiftSchedule.asc.all
    respond_with_json
  end

  def details
    @data_ = details_attrs @shift.details.desc
    respond_with_json
  end

  def create
    @shift = ShiftSchedule.new(params[:shift])
    details_attrs = params[:details]
    details_attrs.each do |attrs|
      detail = ShiftScheduleDetail.new(attrs)
      detail.shift_schedule = @shift
      @shift.details << detail
    end

    if @shift.save
      js_params[:success] = { success: "Shift schedule was created successfully." }
    else
      errors = get_details_errors
      js_params[:errors] = { errors: errors.full_messages.join('<br>') }
    end
    respond_with_json
  end

  def update
    errors = @shift.errors unless @shift.update_attributes(params[:shift])

    js_params[:success] = { success: "Shift Schedule was updated successfully." } unless errors
    js_params[:errors] = { errors: errors.full_messages.join('<br>') } if errors
    respond_with_json
  end

  def destroy
    @shift = ShiftSchedule.find_by_id(params[:id])
    errors = @shift.errors.full_messages unless @shift.destroy

    js_params[:success] = { success: "Shift was deleted successfully." } unless errors
    js_params[:errors]  = { errors: errors } if errors
    respond_with_json
  end

  private
  def details_attrs(collection)
    collection.map do |col|
      am_start = (a=col.am_time_start) ? (a.localtime - a.localtime.utc_offset) : nil
      pm_start = (p=col.pm_time_start) ? (p.localtime - p.localtime.utc_offset) : nil
      col.attributes.merge({
        :local_am_start => am_start,
        :local_pm_start => pm_start
      })
    end
  end

  def get_details_error
    errors = @shift.errors
    if errors[:details].present?
      errors.delete(:details)
      errors[:base] << @shift.details.map { |d| d.errors.full_messages }.flatten.uniq
    end
    errors
  end

  def get_shift
    @shift  = ShiftSchedule.find_by_id(params[:id])
  end

  def respond_with_json
    respond_to do |format|
      format.html { render :template => 'layouts/application' }
      format.json { render :json => (@data_ || js_params).to_json }
    end
  end

  def shift_attrs(collection)
    collection.map do |col|
      col.attributes.merge({
        :editable   => col.is_editable?,
        :cancelable => col.is_cancelable?
      })
    end
  end
end
