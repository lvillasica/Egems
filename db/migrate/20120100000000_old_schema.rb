class OldSchema < ActiveRecord::Migration
  def up
    create_table "users", :force => true do |t|
      t.column "login", :string
      t.column "email", :string
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "employee_id", :integer, :default => 0, :null => false
      t.column "enabled", :integer, :default => 0
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
      t.column "remember_token", :string
      t.column "remember_token_expires_at", :datetime
      t.column "role_id", :integer, :default => 0
    end

    add_index "users", ["login"], :name => "users_login_index"
    add_index "users", ["email"], :name => "users_email_index"

    create_table "shift_schedule_details", :force => true do |t|
      t.column "shift_schedule_id", :integer, :default => 0, :null => false
      t.column "day_of_week", :integer, :default => 0, :null => false
      t.column "am_time_start", :datetime
      t.column "am_time_duration", :integer, :default => 0
      t.column "am_time_allowance", :integer, :default => 0
      t.column "pm_time_start", :datetime
      t.column "pm_time_duration", :integer, :default => 0
      t.column "pm_time_allowance", :integer, :default => 0
      t.column "differential_rate", :float, :default => 0.0
    end

    add_index "shift_schedule_details", ["shift_schedule_id", "day_of_week"], :name => "shift_schedule_details_shift_schedule_id_index"

    create_table "shift_schedules", :force => true do |t|
      t.column "name", :string, :default => "", :null => false
      t.column "description", :string, :default => "", :null => false
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
      t.column "is_strict", :integer, :default => 1, :null => false
      t.column "is_custom", :integer, :default => 0, :null => false
      t.column "differential_rate", :float, :default => 0.0
    end

    add_index "shift_schedules", ["name"], :name => "shift_schedules_name_index"
  end

  def down
    drop_table "users"
  end
end
