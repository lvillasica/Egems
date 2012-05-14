# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120509075116) do

  create_table "employee_timesheets", :force => true do |t|
    t.integer  "employee_id",                       :default => 0, :null => false
    t.datetime "date",                                             :null => false
    t.datetime "time_in"
    t.datetime "time_out"
    t.integer  "duration",                          :default => 0
    t.string   "remarks"
    t.integer  "is_late",                           :default => 0
    t.integer  "minutes_late",                      :default => 0
    t.integer  "is_undertime",                      :default => 0
    t.integer  "minutes_undertime",                 :default => 0
    t.datetime "created_on"
    t.integer  "created_by"
    t.datetime "updated_on"
    t.integer  "updated_by"
    t.integer  "is_valid",                          :default => 0
    t.integer  "is_day_awol",                       :default => 0
    t.integer  "is_am_awol",                        :default => 0
    t.integer  "is_pm_awol",                        :default => 0
    t.integer  "minutes_excess",                    :default => 0
    t.integer  "is_excess_minutes_applied",         :default => 0
    t.integer  "allowance_minutes_applied",         :default => 0
    t.integer  "overtime_minutes_applied",          :default => 0
    t.integer  "shift_schedule_id",                 :default => 0, :null => false
    t.integer  "shift_schedule_detail_id",          :default => 0, :null => false
    t.integer  "next_day_shift_schedule_id",        :default => 0, :null => false
    t.integer  "next_day_shift_schedule_detail_id", :default => 0, :null => false
  end

  add_index "employee_timesheets", ["employee_id", "date"], :name => "employee_timesheets_employee_id_index"
  add_index "employee_timesheets", ["is_late", "employee_id", "date"], :name => "employee_timesheets_is_late_index"
  add_index "employee_timesheets", ["is_undertime", "employee_id", "date"], :name => "employee_timesheets_is_undertime_index"
  add_index "employee_timesheets", ["is_valid", "employee_id", "date"], :name => "employee_timesheets_is_valid_index"

  create_table "shift_schedule_details", :force => true do |t|
    t.integer  "shift_schedule_id", :default => 0,   :null => false
    t.integer  "day_of_week",       :default => 0,   :null => false
    t.datetime "am_time_start"
    t.integer  "am_time_duration",  :default => 0
    t.integer  "am_time_allowance", :default => 0
    t.datetime "pm_time_start"
    t.integer  "pm_time_duration",  :default => 0
    t.integer  "pm_time_allowance", :default => 0
    t.float    "differential_rate", :default => 0.0
  end

  add_index "shift_schedule_details", ["shift_schedule_id", "day_of_week"], :name => "shift_schedule_details_shift_schedule_id_index"

  create_table "shift_schedules", :force => true do |t|
    t.string   "name",              :default => "",  :null => false
    t.string   "description",       :default => "",  :null => false
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "is_strict",         :default => 1,   :null => false
    t.integer  "is_custom",         :default => 0,   :null => false
    t.float    "differential_rate", :default => 0.0
  end

  add_index "shift_schedules", ["name"], :name => "shift_schedules_name_index"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "encrypted_password",        :limit => 40
    t.string   "password_salt",             :limit => 40
    t.integer  "employee_id",                             :default => 0, :null => false
    t.integer  "enabled",                                 :default => 0
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "role_id",                                 :default => 0
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "altered_users_email_index"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "altered_users_login_index"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
