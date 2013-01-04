class ShiftSchedulesController < ApplicationController

  respond_to :json
  before_filter :authenticate_user!
  before_filter :get_shift, :except => [:index, :create]

  def index
    #don't store data in data-container
    @data_ = shift_attrs ShiftSchedule.asc.all
    respond_with_json
  end

  def details
    @data_ = details_attrs @shift.details.desc
    respond_with_json
  end

  def employees
    @data_ = Array.new
    employee_attrs @shift.employee_shift_schedules.group_by(&:employee_id)
    respond_with_json
  end

  def add_employee
    shift_employee = @shift.employee_shift_schedules.create(params[:employee])
    if (errors=shift_employee.errors).empty?
      js_params[:shift] = shift_attrs @shift
      js_params[:success] = { success: "Employee was mapped to shift schedule successfully." }
    else
      js_params[:errors] = { error: errors.full_messages.join("<br>") }
    end
    respond_with_json
  end

  def update_employee
    shift_employee = EmployeeShiftSchedule.find_by_id(params[:employee_id])
    shift_employee.update_attributes(params[:employee])

    if (errors=shift_employee.errors).empty?
      js_params[:shift] = shift_attrs @shift
      js_params[:success] = { success: "Employee was mapped to shift schedule successfully." }
    else
      js_params[:errors] = { error: errors.full_messages.join("<br>") }
    end
    respond_with_json
  end

  def remove_employee
    employee = @shift.employee_shift_schedules.find_by_id(params[:employee_id])
    errors = employee.errors unless employee.destroy
    js_params[:shift] = shift_attrs @shift
    js_params[:success] = { success: "Employee mapping to shift schedule was removed successfully." } unless errors
    js_params[:errors] = { error: errors.full_messages.join("<br>") } if errors
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
    if @shift.update_attributes_with_details(params[:shift])
      js_params[:success] = { success: "Shift Schedule was updated successfully." }
    else
      errors = get_details_errors
      js_params[:errors] = { errors: errors.full_messages.join('<br>') }
    end
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
      am_start = (a=col.am_time_start) ? a : nil
      pm_start = (p=col.pm_time_start) ? p : nil
      col.attributes.merge({
        :local_am_start => am_start,
        :local_pm_start => pm_start
      })
    end
  end

  def get_details_errors
    errors = @shift.errors
    if (derrors = errors.keys.grep(/^details($|.)/)).present?
      derrors.each { |d| errors.delete(d) }
      @shift.details.each do |detail|
        e = detail.errors.full_messages
        errors[:base] << "#{detail.abbr_day_name}: #{e.join("<br>")}" if e.present?
      end
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

  def employee_attrs(collection)
    collection.map do |k, employees|
      employee = Employee.select(:full_name).find_by_id(k)
      employees.map do |emp|
        @data_ << emp.attributes.merge({ :full_name => employee.full_name })
      end if employee
    end
  end

  def shift_attrs(collection)
    if collection.is_a? Array
      collection.map do |col|
        col.attributes.merge({
          :editable   => col.is_editable?,
          :cancelable => col.is_cancelable?
        })
      end
    elsif collection.is_a? ShiftSchedule
      shift = collection
      shift.attributes.merge({
        :editable   => shift.is_editable?,
        :cancelable => shift.is_cancelable?
      })
    end
  end
end
