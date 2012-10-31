class ShiftSchedule < ActiveRecord::Base

  attr_accessible :name, :description, :differential_rate, :details_attributes

  validates_presence_of :name, :description, :is_strict, :is_custom

  before_destroy :check_if_cancelable
  before_update  :check_if_editable

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :details, :class_name => 'ShiftScheduleDetail', :dependent => :destroy
  accepts_nested_attributes_for :details
  has_many :timesheets
  has_and_belongs_to_many :employees, :join_table => 'employee_shift_schedules'

  scope :asc, order('name asc')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def check_if_cancelable
    errors[:base] << "Cannot delete shift schedules with assigned employees." unless is_cancelable?
  end

  def check_if_editable
    errors[:base] << "Cannot edit shift schedules with assigned employees." unless is_editable?
  end

  def detail(timein)
    return nil if details.empty?
    details.detect do |detail|
      !detail.is_day_off? && detail.to_shift_range(timein).cover?(timein)
    end || detail_by_day(timein.localtime.to_date.wday)
  end

  def detail_by_day(wday)
    return nil if details.empty?
    details.detect { |d| d.day_of_week == wday }
  end

  def is_editable?
    employees.count == 0 && Employee.where(["shift_schedule_id=?", id]).count == 0
  end

  def is_cancelable?
    employees.count == 0 && Employee.where(["shift_schedule_id=?", id]).count == 0
  end

  def update_attributes_with_details(attrs)
    self.attributes = attrs
    self.save
  end
end
