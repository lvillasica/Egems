class OvertimeAction < ActiveRecord::Base
  self.table_name = "overtime_actions"
  include TimesheetsHelper

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
  # Scopes & Validations
  # -------------------------------------------------------
  validates_presence_of :approved_duration, :response, :responder_id, :on => :update
  validates_numericality_of :approved_duration
  validate :action_validity, :on => :update

  scope :pending, where(["response = 'Pending'"])
  scope :asc, :joins => "JOIN #{Overtime.table_name} as overtimes on overtimes.id = #{self.table_name}.employee_overtime_id",
              :order => "overtimes.date_of_overtime"


  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_create :set_default_responders
  before_create :set_timestamps

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def action_validity
    valid_duration = Range.new((1.hour/1.minute), overtime.duration)
    unless valid_duration.cover?(approved_duration)
      errors[:approved_duration] << "must be greater than 1h, less than #{format_in_hours valid_duration.last}"
    end
  end

  def set_timestamps
    self.created_at = Time.now.utc
    self.updated_at = Time.parse('1970-01-01 08:00:00').utc
  end

  def set_default_responders
    self.responders = [self.overtime.employee.project_manager,
                       self.overtime.employee.immediate_supervisor].compact.uniq
  end

  def approve!(supervisor)
    if supervisor == overtime.employee
      errors[:base] << 'Cannot approve own overtime application.'
    else
      self.responder = supervisor
      self.response  = 'Approved'
      if self.save
        self.overtime.update_column(:status, response)
        self.overtime.update_column(:duration_approved, approved_duration)
        send_email_notification(response.downcase, supervisor)
      end
    end
  end

  def send_email_notification(action, action_owner)
    recipients = Array.new(responders.uniq)
    recipients << overtime.employee unless responders.include?(overtime.employee)

    recipients.uniq.compact.each do |recipient|
      begin
        OvertimeMailer.overtime_action(overtime.employee, overtime, recipient, action, action_owner).deliver
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        errors[:base] << "There was a problem on sending the email notification to #{recipient.email}: #{e.message}"
        next
      end
    end
  end
end
