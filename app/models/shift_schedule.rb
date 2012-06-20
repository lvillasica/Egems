class ShiftSchedule < ActiveRecord::Base

  attr_accessible :name, :description, :differential_rate

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :shift_schedule_details, :dependent => :destroy
  has_many :timesheets
  has_and_belongs_to_many :employees, :join_table => 'employee_shift_schedules'

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def detail(day)
    shift_schedule_details.detect{ |d| d.day_of_week == day }
  end
end
