class CreateEmployeeMappings < ActiveRecord::Migration
  def change
    create_table :employee_mappings do |t|
      t.integer :employee_id
      t.integer :approver_id
      t.string :approver_type
      t.datetime :from
      t.datetime :to
    end
    
    add_index :employee_mappings, [:employee_id, :approver_id]
  end
end
