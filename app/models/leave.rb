class Leave < ActiveRecord::Base

  self.table_name = 'employee_truancies'
  attr_accessible :leave_type, :date_from, :date_to, :leaves_allocated

  SPECIAL_TYPES = ['Maternity Leave', 'Paternity Leave', 'Magna Carta', 'Solo Parent Leave', 'Violence Against Women']

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  has_many :leave_details, :foreign_key => :employee_truancy_id

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

end
