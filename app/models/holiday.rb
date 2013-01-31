class Holiday < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_and_belongs_to_many :branches, :join_table => 'holiday_branches'

  attr_accessible :date, :name, :description, :holiday_type, :ot_rate
  validates_presence_of :date, :name, :description, :holiday_type
  validates_uniqueness_of :date, :message => "has already been set as holiday."
  validate :check_date

  after_save :recompute_leaves
  before_destroy :keep_branches_record
  after_destroy :restore_leaves

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :falls_on, lambda { |date| where(["Date(date) = Date(?)", (date.end_of_day)]) }
  scope :within, lambda { |range|
    from = range.first.beginning_of_day
    to   = range.last.end_of_day
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

  def recompute_leave(leave)
    unit_was = leave.leave_unit
    unit = leave.compute_unit
    leave.update_column(:leave_unit, unit)

    if leave.is_approved?
      unit_change = unit_was - unit
      leave.update_consumed_count(unit_change)
    end

    if !leave.is_rejected? && !leave.is_canceled?
      status = unit < 1 ? 'Holiday' : 'Pending'
      leave.update_column(:status, status)
      leave.remove_response_attrs
    end
  end

  def recompute_leaves
    day = date
    if day > Time.now.beginning_of_day
      if date_changed? && date_was
        #restore previously recomputed leaves
        changed_date = date_was
        changed_leaves = LeaveDetail.filed_for(changed_date)
        changed_leaves.each do |detail|
          branch = detail.employee.branch
          if @branches_was.include?(branch)
            range = Range.new(detail.leave_date, detail.end_date)
            restore_leave(detail) if range.cover?(changed_date)
          end
        end
      end

      leaves = LeaveDetail.filed_for(day)
      leaves.each do |detail|
        branch = detail.employee.branch
        if branches.include?(branch)
          recompute_leave(detail)
        else
          restore_leave(detail) if detail.is_holidayed?
        end
      end
    end
  end

  def restore_leave(leave)
    unit_was = leave.leave_unit
    unit = leave.compute_unit
    leave.update_column(:leave_unit, unit)
    if leave.is_approved?
      unit_change = unit_was - unit
      leave.update_consumed_count(unit_change)
    end

    if !leave.is_rejected? && !leave.is_canceled?
      leave.update_column(:status, 'Pending')
      leave.remove_response_attrs
    end
  end

  def restore_leaves
    day = date.to_date.to_time
    if day > Time.now.beginning_of_day
      leaves = LeaveDetail.filed_for(day)
      leaves.each do |detail|
        branch = detail.employee.branch
        restore_leave(detail) if @branches_was.include?(branch)
      end
    end
  end

  def send_to_den!
    require 'open-uri'
    location = Branch.get_den_location_equivalent(branches)
    pdate    = date.strftime("%Y-%m-%d")
    params   = "?access_token=#{DEN_AUTH_TOKEN}&date=#{pdate}&title=#{name}&description=#{description}&location=#{location}"
    params = URI::encode(params)

    if den_holiday_id && den_holiday_id != 0
      action  = "update"
      params += "&holiday_id=#{den_holiday_id}"
      url     = "#{DEN_URL}/holidays/update_holidays#{params}"
    else
      action  = "create"
      url     = "#{DEN_URL}/holidays/save_holidays#{params}"
    end

    begin
      result = JSON.parse(open(url).read)
      case action
      when "create"
        if result["save_complete"]
          #expecting DEN web service to return id of holiday in DEN
          self.update_column(:den_holiday_id, result["holiday_id"])
        else
          errors[:base] << "There was an error adding the holiday in DEN."
          return false
        end
      when "update"
        unless result["save_complete"]
          errors[:base] << "There was an error updating the holiday in DEN."
          return false
        end
      end
    rescue => error
      puts "<< DEN connection error -----", error
      errors[:base] << "There was an error connecting to DEN."
      return false
    end
    true
  end

  def keep_branches_record
    @branches_was = self.branches.clone()
  end

  def update_attrs_with_branches(attrs, branches)
    keep_branches_record
    self.attributes = attrs
    self.branches = branches
    self.save
  end
end
