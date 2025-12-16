class CreateFeedItems < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_items, collation: 'utf8mb4_general_ci' do |t|
      t.references :feed_source, null: false, foreign_key: true
      t.string :guid, null: false, limit: 500
      t.string :title, null: false, limit: 500
      t.string :url, null: false, limit: 2048
      t.text :description
      t.text :content
      t.string :author, limit: 255
      t.datetime :published_at
      t.datetime :discarded_at

      t.timestamps

      t.index [:feed_source_id, :guid], unique: true, length: { guid: 255 }
      t.index [:feed_source_id, :published_at]
      t.index :discarded_at
    end
  end
end
