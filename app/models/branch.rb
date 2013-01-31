class Branch < ActiveRecord::Base

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_many :employees
  has_and_belongs_to_many :holidays, :join_table => 'holiday_branches'


  def self.get_den_location_equivalent(branches)
    #------------------------------------------------
    # 12/03/2012
    # only 2 branch codes in eGems' DB: CBU, MNL
    # LOCATIONS: (Den constant)
    #   1 => 'Manila'
    #   2 => 'Cebu'
    #   3 => 'Manila & Cebu'
    #   4 => 'Australia'
    #   5 => 'US'
    #   6 => 'All'
    #------------------------------------------------

    branch_codes = branches.map { |b| b.code }
    location = case
      when branch_codes.include?("CBU") && branch_codes.include?("MNL") then 3
      when branch_codes.include?("CBU") then 2
      when branch_codes.include?("MNL") then 1
      else 1
    end
  end

end
