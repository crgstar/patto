class CreateFeedSources < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_sources, collation: 'utf8mb4_general_ci' do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false, limit: 2048
      t.string :title, limit: 255
      t.text :description
      t.datetime :last_fetched_at
      t.string :fetch_error, limit: 1000
      t.datetime :discarded_at

      t.timestamps

      t.index [:user_id, :url], unique: true, length: { url: 255 }
      t.index :discarded_at
    end
  end
end
