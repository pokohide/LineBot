class AddMaxToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :max_step, :integer
  end
end
