class Leave < ActiveRecord::Base

  self.table_name = 'employee_truancies'
  attr_accessible :leave_type, :date_from, :date_to, :leaves_allocated, :w_docs

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
  validates_presence_of :leave_type, :date_from, :date_to, :message => 'is invalid.'
  validates_numericality_of :leaves_allocated, :message => 'is invalid.'
  validate :invalid_leave

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
    where("Date(?) between Date(date_from) and Date(date_to)", date)
  }

  scope :from_timesheets, where(["leave_type not in ('Vacation Leave', 'Maternity Leave', 'Magna Carta')"])

  scope :find_conflict, lambda { |leave|
    where("#{Leave.table_name}.leave_type = ?", leave.leave_type)
    .where(":from between #{Leave.table_name}.date_from and #{Leave.table_name}.date_to or
            :to between #{Leave.table_name}.date_from and #{Leave.table_name}.date_to or
            #{Leave.table_name}.date_from between :from and :to or
            #{Leave.table_name}.date_to between :from and :to",
            { :from => leave.date_from, :to => leave.date_to })
  }

  scope :major_leaves_within, lambda { |from, to|
    where(:leave_type => Leave::MAJOR_TYPES)
    .where("#{Leave.table_name}.date_from >= :from and
            #{Leave.table_name}.date_to <= :to",
            { :from => from, :to => to })
  }

  scope :special_types, where(:leave_type => Leave::SPECIAL_TYPES)

  scope :exclude_ids, lambda { |ids|
    where(["#{Leave.table_name}.id NOT IN (?)", ids]) if ids.any?
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
  def date_from=(date)
    self[:date_from] = Time.parse(date.to_s) rescue nil
  end

  def date_to=(date)
    self[:date_to] = Time.parse(date.to_s) rescue nil
  end

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
    total_alloc = 0.0
    @employee = self.employee
    case self.leave_type
    when 'Sick Leave'
      total_alloc = prorated_alloc(12.0) if @employee
      self.leaves_allocated = total_alloc
    when 'Vacation Leave'
      total_alloc = prorated_alloc(@employee.expected_vl_allocation) if @employee
      self.leaves_allocated = total_alloc
    when 'AWOP'
      self.leaves_allocated = total_alloc
    end
  end

  def prorated_alloc(allocation)
    res = 0.0
    @employee ||= self.employee
    validity_range = (date_from .. date_to)
    emp_hired_date = @employee.date_hired
    res = if @employee.years_from_hired.eql? 0 and validity_range.cover?(emp_hired_date)
      (@employee.date_hired.month .. allocation).count.to_f
    else
      allocation
    end
    res
  end

  def set_consumed
    self.leaves_consumed = 0.0
  end

  def max_credits
    credits = case leave_type
              when 'Paternity Leave' then 7.0
              when 'Maternity Leave' then 72.0
              when 'Solo Parent Leave' then 7.0
              when 'Violence Against Women' then 10.0
              when 'Magna Carta' then 60.0
              end
  end

private
  def invalid_leave
    check_if_changed

    if employee and date_from and date_to
      has_conflict = employee.leaves.exclude_ids([self.id]).find_conflict(self).any?
      errors[:base] << 'Conflict on leave validity.' if has_conflict

      if Leave::SPECIAL_TYPES.include?(leave_type)
        if date_from_changed? and date_from.to_date <= Date.today
          errors[:base] << 'Leave should be for future dates.'
        end

        validate_max_credits
      end

      if date_from > date_to
        errors[:base] << 'From must not be later than To.'
      end

      errors[:base] << 'Employee must be regularized.' unless employee.is_regularized?
    end

    if !self.new_record? and leaves_consumed > 0
      errors[:base] << 'Leave has already been consumed.'
    end
  end

  def check_if_changed
    errors[:base] << 'Nothing changed.' if !self.new_record? and !self.changed?
  end

  def validate_max_credits
    if max_credits and leaves_allocated.to_f > max_credits.to_f
      errors[:leaves_allocated] << "for #{ leave_type } must not exceed to #{ max_credits }."
    end
  end

end
