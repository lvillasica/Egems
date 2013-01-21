class ChangeUsersType < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.change :encrypted_password, :string, :limit => 255
      t.change :password_salt, :string, :limit => 255
    end
  end

  def down
  end
end
