class ShiftSchedule < ActiveRecord::Base

  attr_accessible :name, :description, :differential_rate

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :details, :class_name => 'ShiftScheduleDetail', :dependent => :destroy
  has_many :timesheets
  has_and_belongs_to_many :employees, :join_table => 'employee_shift_schedules'

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
