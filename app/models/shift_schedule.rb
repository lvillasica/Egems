class ShiftSchedule < ActiveRecord::Base

  attr_accessible :name, :description, :differential_rate,
                  :details_attributes, :employees_attributes

  validates_presence_of :name, :description, :is_strict, :is_custom
  validates_numericality_of :differential_rate
  validates_inclusion_of :differential_rate, :in => 0..1

  before_destroy :check_if_cancelable
  before_update  :check_if_editable

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :details, :class_name => 'ShiftScheduleDetail', :dependent => :destroy
  accepts_nested_attributes_for :details
  has_many :timesheets
  has_many :employee_shift_schedules
  has_many :employees, :through => :employee_shift_schedules
  scope :asc, order('name asc')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def differential_rate=(val)
    write_attribute(:differential_rate, val.to_f/100)
  end

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
    end || detail_by_day(timein.to_date.wday)
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
