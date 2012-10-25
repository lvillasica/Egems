class ShiftSchedulesController < ApplicationController

  respond_to :json
  before_filter :authenticate_user!

  def index
    #don't store data in data-container
    @data_ = ShiftSchedule.asc.all
    respond_with_json
  end

  def details
    shift  = ShiftSchedule.find_by_id(params[:id])
    @data_ = attrs shift.details.desc
    respond_with_json
  end

  def new
    shift = ShiftSchedule.new(params[:shift])
    details_attrs = params[:details]
    details_attrs.each do |attrs|
      detail = ShiftScheduleDetail.new(attrs)
      detail.shift_schedule = shift
      shift.details << detail
    end
    if shift.save
      js_params[:success] = { success: "Shift was created successfully." }
    else
      errors = shift.errors
      if errors[:details].present?
        errors.delete(:details)
        errors[:base] << shift.details.map { |d| d.errors.full_messages }.flatten.uniq
      end
      js_params[:errors] = { errors: errors.full_messages.join('<br>') }
    end
    respond_with_json
  end

  private
  def attrs(collection)
    collection.map do |col|
      am_start = (a=col.am_time_start) ? (a.localtime - a.localtime.utc_offset) : nil
      pm_start = (p=col.pm_time_start) ? (p.localtime - p.localtime.utc_offset) : nil
      col.attributes.merge({
        :local_am_start => (am_start),
        :local_pm_start => pm_start
      })
    end
  end

  def respond_with_json
    respond_to do |format|
      format.html { render :template => 'layouts/application' }
      format.json { render :json => (@data_ || js_params).to_json }
    end
  end
end
