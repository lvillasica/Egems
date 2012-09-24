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

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def set_created_on
    self.created_on = Time.now.utc
  end
  
  def set_action
    self.create_action
  end
  
  def reset_status
    self.status = 'Pending' unless self.status.eql?('Pending')
  end
  
  def max_duration
    employee.timesheets.by_date(date_of_overtime.localtime).sum(:minutes_excess)
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

private
  def invalid_input
    if duration.minutes < 1.hour
      errors[:duration] << "must not be less than 1 hour."
    elsif duration.minutes > max_duration.minutes
      errors[:duration] << "must not exceed #{ format_in_hours maxDuration }"
    end
    
    unless ['Pending', 'Rejected'].include?(status)
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
    responders = action.responders
    recipients = Array.new(responders.uniq)
    recipients << employee unless responders.include?(employee)

    recipients.uniq.compact.each do |recipient|
      begin
        case @email_action
        when 'sent', 'edited', 'canceled'
          OvertimeMailer.overtime_for_approval(employee, self, recipient, @email_action).deliver
        # when 'approved', 'rejected'
        #   OvertimeMailer.overtime_action(employee, self, recipient, @email_action, @action_owner).deliver
        end
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        errors[:base] << "There was a problem on sending the email notification to #{recipient.email}: #{e.message}"
        next
      end
    end
  end

end
