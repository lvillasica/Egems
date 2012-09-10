class TimesheetAction < ActiveRecord::Base
  self.table_name = 'timesheet_actions'
  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def before_save
    self.created_at = Time.now if new_record?
    self.updated_at = Time.now
  end
end
