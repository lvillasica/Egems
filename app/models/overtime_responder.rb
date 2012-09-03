class OvertimeResponder < ActiveRecord::Base
  self.table_name = "overtime_actions"

  belongs_to :overtime
end