class CreateChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_items, collation: 'utf8mb4_general_ci' do |t|
      t.references :sticky, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :checked, default: false, null: false
      t.integer :position, default: 0, null: false
      t.datetime :discarded_at

      t.timestamps

      t.index [:sticky_id, :position], name: 'index_checklist_items_on_sticky_and_position'
      t.index :discarded_at
    end
  end
end
