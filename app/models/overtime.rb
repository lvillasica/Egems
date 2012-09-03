class Overtime < ActiveRecord::Base

  self.table_name = 'employee_overtimes'

  attr_accessible :date_filed, :date_of_overtime, :work_details, :duration, :duration_approved, :status

  include ApplicationHelper

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  belongs_to :timesheet
  #belongs_to :responder, :class_name => "Employee", :foreign_key => "responder"
  has_and_belongs_to_many :responders, :class_name => "Employee",
                          :join_table => "overtime_actions",
                          :foreign_key => :employee_overtime_id,
                          :association_foreign_key => :responder_id

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :work_details, :duration
  validates_numericality_of :duration

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_default_responders
  before_create :validate_duration
  #after_create :send_email_notification

  # -------------------------------------------------------
  # Namescope
  # -------------------------------------------------------
  scope :pending, where(:status => 'Pending')

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------

  
  def set_default_responders
    responders = [@employee.project_manager,@employee.immediate_supervisor].compact.uniq
  end

  def get_responders
    responders.map { |responder| responder.full_name  }
  end

  #private
  def get_minutes_excess
    #get the id of the timesheet's overtime and then get the excess of the timesheet
    timesheet_id   = self.id
    excess = @employee.timesheets.find(timesheet_id).minutes_excess

  end

  def validate_duration
    #duration must not exceed the excess hours and must not be less than 0
    unless duration <= get_minutes_excess && duration > 0
      errors[:overtime] << "Duration applied must not be less than 1 and greater than #{get_minutes_excess} minutes."
    end
  end

  def send_email_notification
    #email the respondents for overtime approval
  end

end
