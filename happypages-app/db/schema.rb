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

ActiveRecord::Schema[8.1].define(version: 2026_01_21_110002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.string "referral_code"
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["source"], name: "index_analytics_events_on_source"
  end

  create_table "discount_configs", force: :cascade do |t|
    t.string "config_key", null: false
    t.string "config_value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["config_key"], name: "index_discount_configs_on_config_key", unique: true
  end

  create_table "discount_generations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_current", default: true
    t.string "referred_discount_type", null: false
    t.string "referred_discount_value", null: false
    t.bigint "shared_discount_id", null: false
    t.string "shopify_discount_id"
    t.datetime "updated_at", null: false
    t.index ["shared_discount_id"], name: "index_discount_generations_on_shared_discount_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "discount_generation_id"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "referral_code", null: false
    t.text "referrer_reward_codes", default: [], array: true
    t.string "shopify_customer_id"
    t.string "shopify_discount_id"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.boolean "uses_shared_discount", default: true
    t.index ["discount_generation_id"], name: "index_referrals_on_discount_generation_id"
    t.index ["email"], name: "index_referrals_on_email"
    t.index ["referral_code"], name: "index_referrals_on_referral_code", unique: true
    t.index ["shopify_customer_id"], name: "index_referrals_on_shopify_customer_id"
  end

  create_table "shared_discounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "discount_type", null: false
    t.boolean "is_active", default: false
    t.string "name"
    t.boolean "override_applied", default: false
    t.datetime "override_ends_at"
    t.string "override_referred_type"
    t.string "override_referred_value"
    t.string "override_reward_type"
    t.string "override_reward_value"
    t.datetime "override_starts_at"
    t.string "referred_discount_type"
    t.string "referred_discount_value"
    t.string "referrer_reward_type"
    t.string "referrer_reward_value"
    t.string "shopify_discount_id"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "discount_generations", "shared_discounts"
  add_foreign_key "referrals", "discount_generations"
end
