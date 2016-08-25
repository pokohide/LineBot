class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.integer :r_id
      t.boolean :cook
      t.string :mid
      t.string :name

      t.timestamps
    end
  end
end
