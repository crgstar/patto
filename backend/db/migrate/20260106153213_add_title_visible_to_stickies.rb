class AddTitleVisibleToStickies < ActiveRecord::Migration[8.1]
  def change
    add_column :stickies, :title_visible, :boolean, default: true, null: false
  end
end
