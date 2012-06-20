class Branch < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_many :employees
  has_and_belongs_to_many :holidays, :join_table => 'holiday_branches'

end
