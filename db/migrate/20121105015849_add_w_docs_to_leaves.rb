class AddWDocsToLeaves < ActiveRecord::Migration
  def change
    add_column :employee_truancies, :w_docs, :boolean, :default => false
  end
end
