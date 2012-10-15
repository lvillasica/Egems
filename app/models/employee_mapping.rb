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
  
private
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
    
    validate_all_mapped if new_record?
  end
  
  def validate_all_mapped
    all_mapped = []
    all_mapped << member.approvers
    all_mapped << member.members
    if all_mapped.flatten.include?(approver)
      errors[:base] << "#{ member.full_name } has already been mapped with #{ approver.full_name }."
    end
  end
  
end
