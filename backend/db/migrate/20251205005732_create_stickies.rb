class CreateStickies < ActiveRecord::Migration[8.1]
  def change
    create_table :stickies, collation: 'utf8mb4_general_ci' do |t|
      t.string :type, null: false
      t.string :title
      t.text :content
      t.integer :position, default: 0, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :stickies, [:user_id, :position]
    add_index :stickies, :discarded_at
  end
end
