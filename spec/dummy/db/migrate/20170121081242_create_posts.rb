class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        Post.create_translation_table! title: :string, text: :text, author: :string
        Post.create_automatic_translation_table! :title, :text
      end

      dir.down do
        Post.drop_automatic_translation_table!
        Post.drop_translation_table!
      end
    end
  end
end
