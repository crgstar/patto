# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_05_022559) do
  create_table "stickies", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "position", default: 0, null: false
    t.string "title"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["discarded_at"], name: "index_stickies_on_discarded_at"
    t.index ["user_id", "position"], name: "index_stickies_on_user_id_and_position"
    t.index ["user_id"], name: "index_stickies_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "stickies", "users"
end
