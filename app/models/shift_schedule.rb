class ShiftSchedule < ActiveRecord::Base

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :shift_schedule_details, :dependent => :destroy
  has_many :timesheets

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def detail(day)
    shift_schedule_details.detect{ |d| d.day_of_week == day }
  end
end
