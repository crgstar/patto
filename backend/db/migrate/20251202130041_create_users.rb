class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, charset: 'utf8mb4', collation: 'utf8mb4_general_ci' do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
