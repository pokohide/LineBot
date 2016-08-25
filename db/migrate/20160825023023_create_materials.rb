class CreateMaterials < ActiveRecord::Migration[5.0]
  def change
    create_table :materials do |t|
      t.integer :recipe_id
      t.string :name
      t.string :quantity

      t.timestamps
    end
  end
end
