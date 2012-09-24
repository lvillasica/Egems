class OvertimeAction < ActiveRecord::Base
  self.table_name = "overtime_actions"

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :overtime, :foreign_key => :employee_overtime_id
  belongs_to :responder, :class_name => "Employee", :foreign_key => :responder_id
  has_and_belongs_to_many :responders, :class_name => "Employee",
                          :join_table => "overtime_action_responders",
                          :foreign_key => :overtime_action_id,
                          :association_foreign_key => :responder_id

  # -------------------------------------------------------
  # Scopes
  # -------------------------------------------------------
  scope :pending, where(["response = 'Pending'"])

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_create :set_default_responders
  before_create :set_created_at

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def set_created_at
    self.created_at = Time.now.utc
  end

  def set_default_responders
    self.responders = [self.overtime.employee.project_manager,
                       self.overtime.employee.immediate_supervisor].compact.uniq
  end
end
