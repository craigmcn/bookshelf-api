class CreateTagsAndTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.belongs_to :book, null: false, foreign_key: true
      t.belongs_to :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :taggings, [:book_id, :tag_id], unique: true
  end
end
