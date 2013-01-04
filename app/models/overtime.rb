class Overtime < ActiveRecord::Base

  self.table_name = 'employee_overtimes'

  attr_accessible :date_filed, :date_of_overtime, :work_details, :duration, :duration_approved, :status

  include ApplicationHelper
  include TimesheetsHelper

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  has_one :action, :class_name => "OvertimeAction",
                   :foreign_key => :employee_overtime_id

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :work_details, :duration
  validates_numericality_of :duration
  validate :invalid_input

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_create :set_created_on
  before_create :set_email_action_sent
  before_update :set_email_action_edited
  before_save :reset_status
  after_create :set_action
  after_save :send_email_notification

  # -------------------------------------------------------
  # Namescope
  # -------------------------------------------------------
  scope :editable, where(:status => ['Pending', 'Rejected'])
  scope :asc_by_overtime_date, order(:date_of_overtime)
  scope :within, lambda { |range|
    start_date, end_date = range
    where(["date_of_overtime between ? and ?",
             start_date, end_date]) if start_date and end_date
  }

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def set_created_on
    self.created_on = Time.now
  end

  def set_action
    self.create_action
  end

  def get_responders
    if action.responder
      return [action.responder]
    else
      return action.responders
    end
  end

  def reset_status
    self.status = 'Pending' unless self.status.eql?('Pending')
  end

  def max_duration
    employee.timesheets.by_date(date_of_overtime).sum(:minutes_excess)
  end

  def update_if_changed(attrs)
    # select only attributes to be changed to avoid malicious attacks.
    self.attributes = attrs.symbolize_keys.select do |a|
      [:duration, :work_details].include?(a)
    end

    if changed?
      self.save
    else
      errors[:base] << 'Nothing changed.'
      return false
    end
  end

  def cancel!
    if is_cancelable?
      update_column(:status, 'Canceled')
      @email_action = 'canceled'
      send_email_notification
      return true
    else
      errors[:base] = "Overtime dated on #{ format_date date_of_overtime }
                       with a duration of #{ format_in_hours duration }
                       is not cancelable."
      return false
    end
  end

  def is_cancelable?
    ['Pending', 'Rejected'].include?(status)
  end

  def response_date
    action.updated_at
  end

private
  def invalid_input
    if duration.minutes < 1.hour
      errors[:duration] << "must not be less than 1 hour."
    elsif duration.minutes > max_duration.minutes
      errors[:duration] << "must not exceed #{ format_in_hours maxDuration }"
    end

    unless ['Pending', 'Rejected', 'Un-Filed'].include?(status)
      errors[:base] << "You can no longer edit this entry."
    end
  end

  def set_email_action_sent
    @email_action = 'sent'
  end

  def set_email_action_edited
    @email_action = "edited" if @email_action == 'sent' or @email_action.nil?
  end

  def send_email_notification
    mailing_job = OvertimeRequestsMailingJob.new(self.id, @email_action)
    Delayed::Job.enqueue(mailing_job)
    msg = "Sending email notifications..."
    Rails.cache.write("#{ employee.id }_overtime_request_mailing_stat", ["enqueued", msg])
  end

end
