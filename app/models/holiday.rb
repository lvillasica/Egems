class Holiday < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_and_belongs_to_many :branches, :join_table => 'holiday_branches'

  attr_accessible :date, :name, :description, :holiday_type
  validates_presence_of :date, :name, :description, :holiday_type
  validates_uniqueness_of :date, :message => "has already been set as holiday."
  validate :check_date

  after_save :recompute_leaves
  before_destroy :restore_leaves

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :falls_on, lambda { |date| where(["Date(date) = Date(?)", (date.end_of_day).utc]) }
  scope :within, lambda { |range|
    from = range.first.localtime.beginning_of_day
    to   = range.last.localtime.end_of_day
    where(["date between ? and ?", from, to])
  }

  scope :asc, order("date asc")
  scope :desc, order("date desc")

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def check_date
    if date.to_date <= Time.now.to_date
      errors[:date] << "of holiday must not be today or a past date."
    end
  end

  def is_cancelable?
    date.to_date > Date.today
  end

  def is_editable?
    date.to_date > Date.today
  end

  def recompute_leaves
    day = date.to_date.to_time
    if day > Date.today.to_time
      leaves = LeaveDetail.filed_for(day)
      leaves.each do |detail|
        if branches.include?(detail.employee.branch) && !detail.is_canceled?
          days = detail.leave_unit
          status = days <= 1 ? 'Canceled' : 'Pending'
          detail.update_consumed_count(0-days) if detail.is_approved?
          detail.remove_response_attrs
          detail.update_column(:status, status)
          detail.update_column(:leave_unit, days-1) if days > 1
        end
      end
    end
  end

  def restore_leaves
    day = date.to_date.to_time
    if day > Date.today.to_time
      leaves = LeaveDetail.filed_for(day)
      leaves.each do |detail|
        if branches.include?(detail.employee.branch)
          days = detail.leave_unit
          detail.update_consumed_count(0-days) if detail.is_approved?
          detail.remove_response_attrs
          detail.update_column(:status, 'Pending')
          detail.update_column(:leave_unit, days+1) if days > 1
        end
      end
    end
  end
end
