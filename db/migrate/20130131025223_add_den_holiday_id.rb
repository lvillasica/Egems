class AddDenHolidayId < ActiveRecord::Migration
  def self.up
    unless column_exists? :holidays, :den_holiday_id
      add_column :holidays, :den_holiday_id, :integer, :default => 0
    end
  end

  def self.down
    if column_exists? :holidays, :den_holiday_id
      remove_column :holidays, :den_holiday_id
    end
  end
end
