class EmployeeMapping < ActiveRecord::Base
  attr_accessible :approver_id, :approver_type, :employee_id, :from, :to
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :approver, :foreign_key => :approver_id, :class_name => 'Employee'
  belongs_to :member, :foreign_key => :employee_id, :class_name => 'Employee'
  
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_inclusion_of :approver_type, :in => ['Supervisor/TL', 'Project Manager'], :message => 'is invalid'
  validate :invalid_mapping, :if => :valid_dates
  validates_presence_of :approver_id, :employee_id, :approver_type, :from, :to, :message => 'is invalid.'

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  after_save :reset_responders
  after_destroy :reset_responders
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :sups, where(:approver_type => 'Supervisor/TL')
  scope :pms, where(:approver_type => 'Project Manager')
  scope :conflicts_on_dates, lambda { | from, to |
    where("? between employee_mappings.from and employee_mappings.to or
           ? between employee_mappings.from and employee_mappings.to", from, to)
    where("employee_mappings.from between ? and ? or
           employee_mappings.to between ? and ?", from, to, from, to)
  }
  scope :exclude_ids, lambda { |ids|
    where(["employee_mappings.id NOT IN (?)", ids]) if ids.any?
  }
  
  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def with_names(mapping)
      mapping = mapping.to_sym
      all.map do | employee_mapping |
        employee_mapping.attributes.merge({
          :full_name => employee_mapping.send(mapping).full_name
        })
      end
    end
  end
  
  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def from=(date)
    self[:from] = Time.parse(date.to_s).utc rescue nil
  end
  
  def to=(date)
    self[:to] = Time.parse(date.to_s).utc rescue nil
  end
  
  def update_if_changed(attrs)
    # select only attributes to be changed to avoid malicious attacks.
    self.attributes = attrs.symbolize_keys.select do |a|
      [:approver_type, :from, :to].include?(a)
    end
    
    if changed?
      self.save
    else
      errors[:base] << 'Nothing changed.'
      return false
    end
  end
  
  def reset_responders
    @new_range = [from.localtime, to.localtime]
    @old_range = [from_was.localtime, to_was.localtime] rescue []
    timesheets = objs_to_reset_responders(:timesheets)
    overtimes = objs_to_reset_responders(:overtimes)
    leave_details = objs_to_reset_responders(:leave_details)
    
    timesheets.each do |timesheet|
      t_date = timesheet.date.localtime
      timesheet.reset_responders(member.responders_on(t_date))
    end
    overtimes.each do |overtime|
      ot_date = overtime.date_of_overtime
      overtime.action.reset_responders(member.responders_on(ot_date))
    end
    leave_details.each do |leave_detail|
      ld_date = leave_detail.leave_date.localtime
      leave_detail.reset_responders(member.responders_on(ld_date))
    end
  end
  
private
  def objs_to_reset_responders(obj_name)
    old_obj = member.send(obj_name.to_sym).within(@old_range) rescue []
    new_obj = member.send(obj_name.to_sym).within(@new_range) rescue []
    old_obj | new_obj
  end
  
  def valid_dates
    Time.parse(from.to_s) rescue self.from = nil
    Time.parse(to.to_s) rescue self.to = nil
    from && to
  end
  
  def invalid_mapping
    if from > to
      errors[:from] << 'should not be later than To'
    end
    
    if approver.eql? member
      errors[:base] << "You can't be your own Supervisor / PM / Member."
    end
    
    validate_conflict
  end
  
  def validate_conflict
    if EmployeeMapping.where(:approver_id => approver.id, :employee_id => member.id)
                      .exclude_ids([self.id]).conflicts_on_dates(from, to).any? or
       EmployeeMapping.where(:approver_id => member.id, :employee_id => approver.id)
                      .exclude_ids([self.id]).conflicts_on_dates(from, to).any?
      errors[:base] << "Conflicting dates."
    end
  end
  
end
