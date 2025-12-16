class CreateUserFeedItems < ActiveRecord::Migration[8.1]
  def change
    create_table :user_feed_items, collation: 'utf8mb4_general_ci' do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feed_item, null: false, foreign_key: true
      t.boolean :read, default: false, null: false
      t.datetime :read_at
      t.boolean :starred, default: false, null: false
      t.datetime :discarded_at

      t.timestamps

      t.index [:user_id, :feed_item_id], unique: true
      t.index [:user_id, :read]
      t.index [:user_id, :starred]
      t.index :discarded_at
    end
  end
end
