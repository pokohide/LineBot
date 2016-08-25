class AddColumnToRecipe < ActiveRecord::Migration[5.0]
  def change
    add_column :recipes, :fee, :string
    add_column :recipes, :time, :string
    add_column :recipes, :portion, :string
  end
end
