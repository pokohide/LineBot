class AddNowToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :now_step, :integer
  end
end
