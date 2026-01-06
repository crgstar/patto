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

ActiveRecord::Schema[8.1].define(version: 2026_01_06_153213) do
  create_table "checklist_items", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "position", default: 0, null: false
    t.bigint "sticky_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_checklist_items_on_discarded_at"
    t.index ["sticky_id", "position"], name: "index_checklist_items_on_sticky_and_position"
    t.index ["sticky_id"], name: "index_checklist_items_on_sticky_id"
  end

  create_table "feed_items", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "author"
    t.text "content"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.bigint "feed_source_id", null: false
    t.string "guid", limit: 500, null: false
    t.datetime "published_at"
    t.string "title", limit: 500, null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 2048, null: false
    t.index ["discarded_at"], name: "index_feed_items_on_discarded_at"
    t.index ["feed_source_id", "guid"], name: "index_feed_items_on_feed_source_id_and_guid", unique: true, length: { guid: 255 }
    t.index ["feed_source_id", "published_at"], name: "index_feed_items_on_feed_source_id_and_published_at"
    t.index ["feed_source_id"], name: "index_feed_items_on_feed_source_id"
  end

  create_table "feed_sources", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "fetch_error", limit: 1000
    t.datetime "last_fetched_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", limit: 2048, null: false
    t.bigint "user_id", null: false
    t.index ["discarded_at"], name: "index_feed_sources_on_discarded_at"
    t.index ["user_id", "url"], name: "index_feed_sources_on_user_id_and_url", unique: true, length: { url: 255 }
    t.index ["user_id"], name: "index_feed_sources_on_user_id"
  end

  create_table "stickies", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "height", default: 1, null: false
    t.integer "position", default: 0, null: false
    t.string "title"
    t.boolean "title_visible", default: true, null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "width", default: 1, null: false
    t.integer "x", default: 0, null: false
    t.integer "y", default: 0, null: false
    t.index ["discarded_at"], name: "index_stickies_on_discarded_at"
    t.index ["user_id", "position"], name: "index_stickies_on_user_id_and_position"
    t.index ["user_id", "x", "y"], name: "index_stickies_on_user_id_and_x_and_y"
    t.index ["user_id"], name: "index_stickies_on_user_id"
  end

  create_table "sticky_feed_sources", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "feed_source_id", null: false
    t.integer "position", default: 0, null: false
    t.bigint "sticky_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_sticky_feed_sources_on_discarded_at"
    t.index ["feed_source_id"], name: "index_sticky_feed_sources_on_feed_source_id"
    t.index ["sticky_id", "feed_source_id"], name: "index_sticky_feed_sources_on_sticky_id_and_feed_source_id", unique: true
    t.index ["sticky_id", "position"], name: "index_sticky_feed_sources_on_sticky_id_and_position"
    t.index ["sticky_id"], name: "index_sticky_feed_sources_on_sticky_id"
  end

  create_table "user_feed_items", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "feed_item_id", null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.boolean "starred", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["discarded_at"], name: "index_user_feed_items_on_discarded_at"
    t.index ["feed_item_id"], name: "index_user_feed_items_on_feed_item_id"
    t.index ["user_id", "feed_item_id"], name: "index_user_feed_items_on_user_id_and_feed_item_id", unique: true
    t.index ["user_id", "read"], name: "index_user_feed_items_on_user_id_and_read"
    t.index ["user_id", "starred"], name: "index_user_feed_items_on_user_id_and_starred"
    t.index ["user_id"], name: "index_user_feed_items_on_user_id"
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

  add_foreign_key "checklist_items", "stickies"
  add_foreign_key "feed_items", "feed_sources"
  add_foreign_key "feed_sources", "users"
  add_foreign_key "stickies", "users"
  add_foreign_key "sticky_feed_sources", "feed_sources"
  add_foreign_key "sticky_feed_sources", "stickies"
  add_foreign_key "user_feed_items", "feed_items"
  add_foreign_key "user_feed_items", "users"
end
