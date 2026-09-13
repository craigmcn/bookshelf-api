class AddCategoryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :category, :string, default: "genre", null: false
    add_index :tags, :category
  end
end
