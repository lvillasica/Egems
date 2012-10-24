class Leave < ActiveRecord::Base

  self.table_name = 'employee_truancies'
  attr_accessible :leave_type, :date_from, :date_to, :leaves_allocated

  SPECIAL_TYPES = ['Maternity Leave', 'Paternity Leave', 'Magna Carta', 'Solo Parent Leave', 'Violence Against Women']
  MAJOR_TYPES = ['Sick Leave', 'Vacation Leave', 'AWOP']

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  has_many :leave_details, :foreign_key => :employee_truancy_id
  
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :leave_type, :date_from, :date_to
  validate :leave_validity
  
  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_create :set_allocation
  before_create :set_consumed

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :active, where("status = 1")
  scope :order_by_id, order(:id)
  scope :type, lambda { |type|
    type = "Vacation Leave" if type == "Emergency Leave"
    where(:leave_type => type).order(:id, :created_on)
  }
  scope :within_validity, lambda { |date|
    where("? between date_from and date_to", date)
  }

  scope :from_timesheets, where(["leave_type not in ('Vacation Leave', 'Maternity Leave', 'Magna Carta')"])
  
  scope :find_conflict, lambda { |leave|
    where("#{Leave.table_name}.leave_type = ?", leave.leave_type)
    .where(":from between #{Leave.table_name}.date_from and #{Leave.table_name}.date_to or
            :to between #{Leave.table_name}.date_from and #{Leave.table_name}.date_to or
            #{Leave.table_name}.date_from between :from and :to or
            #{Leave.table_name}.date_to between :from and :to",
            { :from => leave.date_from.utc, :to => leave.date_to.utc })
  }
  
  scope :major_leaves_within, lambda { |from, to|
    where(:leave_type => Leave::MAJOR_TYPES)
    .where("#{Leave.table_name}.date_from >= :from and
            #{Leave.table_name}.date_to <= :to",
            { :from => from.utc, :to => to.utc })
  }

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def leave_types
      types = self.all.map(&:leave_type).compact
      types << "Emergency Leave" if types.include?("Vacation Leave")
      types
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def active?
    status == 1
  end

  def remaining_balance
    allocated = leaves_allocated.to_f
    consumed = leaves_consumed.to_f
    balance = allocated - (consumed + total_pending)
    (balance.to_f >= 0 ? balance.to_f : 0.0)
  end

  def total_pending
    leave_details.pending.sum(:leave_unit)
  end

  def destroy
    if !leave_details.blank?
      errors[:base] << 'Cannot delete this leave.'
      return false
    else
      super
    end
  end
  
  def set_allocation
    case self.leave_type
    when 'Sick Leave'
      self.leaves_allocated = 12.0
    when 'Vacation Leave'
      self.leaves_allocated = self.employee.expected_vl_allocation if self.employee
    when 'AWOP'
      self.leaves_allocated = 0.0
    end
  end
  
  def set_consumed
    self.leaves_consumed = 0.0
  end
  
private
  def leave_validity
    # TODO exclude self
    if employee
      errors[:base] << "Conflict on leave validity." if employee.leaves.find_conflict(self).any?
    end
  end
  
end
