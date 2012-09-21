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
  before_save :reset_status
  after_create :set_action
  #after_create :send_email_notification

  # -------------------------------------------------------
  # Namescope
  # -------------------------------------------------------
  scope :pending, where(:status => 'Pending')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def set_created_on
    self.created_on = Time.now.utc
  end
  
  def set_action
    self.create_action
  end
  
  def set_default_responders
    #self.responders << [@employee.project_manager,@employee.immediate_supervisor].compact.uniq
  end

  def get_responders
    #responders.map { |responder| responder.full_name }
  end
  
  def reset_status
    self.status = 'Pending' unless self.status.eql?('Pending')
  end
  
  def maxDuration
    employee.timesheets.by_date(date_of_overtime.localtime).sum(:minutes_excess)
  end

  def invalid_input
    if duration.minutes < 1.hour
      errors[:duration] << "must not be less than 1 hour."
    elsif duration.minutes > maxDuration.minutes
      errors[:duration] << "must not exceed #{ format_in_hours maxDuration }"
    end
  end

  def send_email_notification
    #email the respondents for overtime approval
  end

end
