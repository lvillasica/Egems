class Timesheet < ActiveRecord::Base
  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  belongs_to :user, :foreign_key => :employee_id
end
