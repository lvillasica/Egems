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
    if response == 'Approved'
      max_duration = overtime.duration
      if approved_duration.minutes < 1.hour
        errors[:approved_duration] << "must not be less than 1 hour."
      elsif approved_duration.minutes > max_duration.minutes
        errors[:approved_duration] << "must not exceed #{ format_in_hours max_duration }"
      end
    end
  end

  def set_timestamps
    self.created_at = Time.now
    self.updated_at = Time.parse('1970-01-01 08:00:00')
  end

  def set_default_responders
    ot_date = overtime.date_of_overtime
    self.responders = self.overtime.employee.responders_on(ot_date).compact.uniq
  end

  def reset_responders(responders=[])
    self.responders = responders.compact.uniq
    self.responders.reset
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

  def reject!(supervisor)
    if supervisor == overtime.employee
      errors[:base] << 'Cannot reject own overtime application.'
    else
      self.responder = supervisor
      self.response  = 'Rejected'
      if self.save
        self.overtime.update_column(:status, response)
        self.overtime.update_column(:duration_approved, 0)
        send_email_notification(response.downcase, supervisor)
      end
    end
  end

  def send_email_notification(action, action_owner)
    Delayed::Job.enqueue(OvertimeActionedMailingJob.new(self.id, action, action_owner.id))
    msg = "Sending email notifications..."
    Rails.cache.write("#{action_owner.id}_overtime_action_mailing_stat", ["enqueued", msg])
  end
end
