class Holiday < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_and_belongs_to_many :branches, :join_table => 'holiday_branches'

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :falls_on, lambda { |date| where(["Date(date) = Date(?)", (date.end_of_day).utc]) }
  scope :within, lambda { |range|
    from = range.first.localtime.beginning_of_day.utc
    to   = range.last.localtime.end_of_day.utc
    where(["Date(date) between ? and ?", from, to])
  }

end
