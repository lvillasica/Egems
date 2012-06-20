class Holiday < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_and_belongs_to_many :branches, :join_table => 'holiday_branches'

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :falls_on, lambda { |date|
    where("date = ?", (date.beginning_of_day + 8.hours).utc)
  }

end
