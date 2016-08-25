class AddBinaryToRecipe < ActiveRecord::Migration[5.0]
  def change
    add_column :recipes, :main, :binary
  end
end
