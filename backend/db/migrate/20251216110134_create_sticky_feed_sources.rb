class CreateStickyFeedSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sticky_feed_sources, collation: 'utf8mb4_general_ci' do |t|
      t.references :sticky, null: false, foreign_key: true
      t.references :feed_source, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.datetime :discarded_at

      t.timestamps

      t.index [:sticky_id, :feed_source_id], unique: true
      t.index [:sticky_id, :position]
      t.index :discarded_at
    end
  end
end
