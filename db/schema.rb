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

ActiveRecord::Schema[7.0].define(version: 2023_02_05_194806) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "creatures", force: :cascade do |t|
    t.integer "no", null: false
    t.string "name", null: false
    t.integer "type1", null: false
    t.integer "type2"
    t.integer "total", null: false
    t.integer "hp", null: false
    t.integer "attack", null: false
    t.integer "defense", null: false
    t.integer "special_attack", null: false
    t.integer "special_defense", null: false
    t.integer "speed", null: false
    t.integer "generation", default: 1, null: false
    t.boolean "legendary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attack"], name: "index_creatures_on_attack"
    t.index ["defense"], name: "index_creatures_on_defense"
    t.index ["generation"], name: "index_creatures_on_generation"
    t.index ["hp"], name: "index_creatures_on_hp"
    t.index ["legendary"], name: "index_creatures_on_legendary"
    t.index ["name"], name: "index_creatures_on_name", unique: true
    t.index ["no"], name: "index_creatures_on_no"
    t.index ["type1"], name: "index_creatures_on_type1"
    t.index ["type2"], name: "index_creatures_on_type2"
  end

end
