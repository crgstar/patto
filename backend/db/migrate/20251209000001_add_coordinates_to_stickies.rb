class AddCoordinatesToStickies < ActiveRecord::Migration[8.1]
  def change
    add_column :stickies, :x, :integer, default: 0, null: false
    add_column :stickies, :y, :integer, default: 0, null: false
    add_column :stickies, :width, :integer, default: 1, null: false
    add_column :stickies, :height, :integer, default: 1, null: false

    # 既存データの移行（position順に3列グリッドで配置）
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.stickies.order(:position).each_with_index do |sticky, index|
            col = index % 3
            row = index / 3
            sticky.update_columns(
              x: col * 2,
              y: row * 2,
              width: 1,
              height: 1
            )
          end
        end
      end
    end

    add_index :stickies, [:user_id, :x, :y]
  end
end
