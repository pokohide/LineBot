class CreateSteps < ActiveRecord::Migration[5.0]
  def change
    create_table :steps do |t|
      t.integer :recipe_id
      t.string :image
      t.string :content
      t.integer :turn

      t.timestamps
    end
  end
end
