class TimesheetAction < ActiveRecord::Base
  self.table_name = 'timesheet_actions'
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :pending_or_rejected, where("response = 'Pending' or response = 'Rejected'")
  
  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def before_save
    self.created_at = Time.now if new_record?
    self.updated_at = Time.now
  end
  
  def is_pending?
    response.eql? 'Pending'
  end
end
