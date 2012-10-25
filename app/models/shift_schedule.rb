class ShiftSchedule < ActiveRecord::Base

  attr_accessible :name, :description, :differential_rate

  validates_presence_of :name, :description, :is_strict, :is_custom
  validates_length_of :name, :minimum => 3
  validates_length_of :description, :minimum => 3

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :details, :class_name => 'ShiftScheduleDetail', :dependent => :destroy
  has_many :timesheets
  has_and_belongs_to_many :employees, :join_table => 'employee_shift_schedules'

  scope :asc, order('name asc')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
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
end
