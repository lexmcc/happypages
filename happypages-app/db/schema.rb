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

ActiveRecord::Schema[8.1].define(version: 2026_02_11_100001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.string "referral_code"
    t.bigint "shop_id", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["shop_id"], name: "index_analytics_events_on_shop_id"
    t.index ["source"], name: "index_analytics_events_on_source"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor", null: false
    t.string "actor_identifier"
    t.string "actor_ip"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}
    t.bigint "resource_id"
    t.string "resource_type"
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["shop_id", "created_at"], name: "index_audit_logs_on_shop_id_and_created_at"
    t.index ["shop_id"], name: "index_audit_logs_on_shop_id"
  end

  create_table "discount_configs", force: :cascade do |t|
    t.string "config_key", null: false
    t.string "config_value", null: false
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "config_key"], name: "index_discount_configs_on_shop_id_and_config_key", unique: true
    t.index ["shop_id"], name: "index_discount_configs_on_shop_id"
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

  create_table "referral_rewards", force: :cascade do |t|
    t.datetime "applied_at"
    t.string "awtomic_customer_id"
    t.string "awtomic_subscription_id"
    t.datetime "cancelled_at"
    t.string "code", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "referral_id", null: false
    t.string "shopify_discount_id"
    t.string "shopify_order_id"
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_number", null: false
    t.index ["awtomic_subscription_id"], name: "index_referral_rewards_on_awtomic_subscription_id"
    t.index ["code"], name: "index_referral_rewards_on_code", unique: true
    t.index ["referral_id", "shopify_order_id"], name: "index_referral_rewards_on_referral_id_and_shopify_order_id", unique: true
    t.index ["referral_id"], name: "index_referral_rewards_on_referral_id"
    t.index ["status", "expires_at"], name: "index_referral_rewards_on_status_and_expires_at"
    t.index ["status"], name: "index_referral_rewards_on_status"
  end

  create_table "referrals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "discount_generation_id"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "referral_code", null: false
    t.text "referrer_reward_codes", default: [], array: true
    t.datetime "reminder_sent_at"
    t.bigint "shop_id", null: false
    t.string "shopify_customer_id"
    t.string "shopify_discount_id"
    t.datetime "subscription_applied_at"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.boolean "uses_shared_discount", default: true
    t.index ["discount_generation_id"], name: "index_referrals_on_discount_generation_id"
    t.index ["shop_id", "email"], name: "index_referrals_on_shop_id_and_email"
    t.index ["shop_id", "referral_code"], name: "index_referrals_on_shop_id_and_referral_code", unique: true
    t.index ["shop_id", "shopify_customer_id"], name: "index_referrals_on_shop_id_and_shopify_customer_id"
    t.index ["shop_id"], name: "index_referrals_on_shop_id"
  end

  create_table "shared_discounts", force: :cascade do |t|
    t.boolean "applies_on_one_time_purchase", default: true
    t.boolean "applies_on_subscription", default: true
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
    t.bigint "shop_id", null: false
    t.string "shopify_discount_id"
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_shared_discounts_on_shop_id"
  end

  create_table "shop_credentials", force: :cascade do |t|
    t.string "api_endpoint"
    t.string "api_key"
    t.string "awtomic_api_key"
    t.string "awtomic_webhook_secret"
    t.datetime "created_at", null: false
    t.string "klaviyo_api_key"
    t.bigint "shop_id", null: false
    t.string "shopify_access_token"
    t.string "shopify_webhook_secret"
    t.datetime "updated_at", null: false
    t.string "webhook_secret"
    t.index ["shop_id"], name: "index_shop_credentials_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "name", null: false
    t.jsonb "platform_config", default: {}
    t.string "platform_type", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_shops_on_domain", unique: true
    t.index ["platform_type"], name: "index_shops_on_platform_type"
    t.index ["slug"], name: "index_shops_on_slug", unique: true
    t.index ["status"], name: "index_shops_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.bigint "shop_id", null: false
    t.string "shopify_user_id"
    t.datetime "updated_at", null: false
    t.index ["shop_id", "email"], name: "index_users_on_shop_id_and_email", unique: true
    t.index ["shop_id", "shopify_user_id"], name: "index_users_on_shop_id_and_shopify_user_id", unique: true
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  add_foreign_key "analytics_events", "shops"
  add_foreign_key "audit_logs", "shops"
  add_foreign_key "discount_configs", "shops"
  add_foreign_key "discount_generations", "shared_discounts"
  add_foreign_key "referral_rewards", "referrals"
  add_foreign_key "referrals", "discount_generations"
  add_foreign_key "referrals", "shops"
  add_foreign_key "shared_discounts", "shops"
  add_foreign_key "shop_credentials", "shops"
  add_foreign_key "users", "shops"
end
