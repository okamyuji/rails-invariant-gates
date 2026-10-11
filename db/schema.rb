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

ActiveRecord::Schema[8.1].define(version: 2026_10_11_000002) do
  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "total_stock", null: false
    t.integer "available_stock", null: false
    t.integer "reserved_stock", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "(`available_stock` + `reserved_stock`) = `total_stock`", name: "products_stock_conservation"
    t.check_constraint "`available_stock` >= 0", name: "products_available_stock_non_negative"
    t.check_constraint "`reserved_stock` >= 0", name: "products_reserved_stock_non_negative"
    t.check_constraint "`total_stock` >= 0", name: "products_total_stock_non_negative"
  end
end
