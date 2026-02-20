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

ActiveRecord::Schema[8.1].define(version: 2026_02_19_160001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.bigint "analytics_site_id", null: false
    t.string "browser", limit: 64
    t.string "browser_version", limit: 32
    t.string "city", limit: 128
    t.string "country_code", limit: 2
    t.string "device_type", limit: 16
    t.string "event_name", limit: 64, default: "pageview", null: false
    t.string "hostname", limit: 255
    t.timestamptz "occurred_at", default: -> { "now()" }, null: false
    t.string "os", limit: 64
    t.string "os_version", limit: 32
    t.string "pathname", limit: 2048
    t.jsonb "properties", default: {}, null: false
    t.string "referral_code", limit: 64
    t.string "referrer", limit: 2048
    t.string "region", limit: 128
    t.string "session_id", limit: 32, null: false
    t.string "utm_campaign", limit: 255
    t.string "utm_content", limit: 255
    t.string "utm_medium", limit: 255
    t.string "utm_source", limit: 255
    t.string "utm_term", limit: 255
    t.string "visitor_id", limit: 32, null: false
    t.index ["analytics_site_id", "event_name", "occurred_at"], name: "idx_analytics_events_site_event_time"
    t.index ["analytics_site_id", "occurred_at"], name: "idx_analytics_events_site_time"
    t.index ["analytics_site_id", "pathname"], name: "idx_analytics_events_site_path"
    t.index ["analytics_site_id", "visitor_id"], name: "idx_analytics_events_site_visitor"
    t.index ["analytics_site_id"], name: "index_analytics_events_on_analytics_site_id"
    t.index ["referral_code"], name: "idx_analytics_events_referral", where: "(referral_code IS NOT NULL)"
    t.index ["session_id"], name: "idx_analytics_events_session"
  end

  create_table "analytics_payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "analytics_site_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "GBP"
    t.string "order_id"
    t.jsonb "properties", default: {}, null: false
    t.string "referral_code"
    t.string "session_id"
    t.datetime "updated_at", null: false
    t.string "visitor_id", null: false
    t.index ["analytics_site_id", "created_at"], name: "index_analytics_payments_on_analytics_site_id_and_created_at"
    t.index ["analytics_site_id", "order_id"], name: "idx_analytics_payments_site_order", unique: true
    t.index ["analytics_site_id", "referral_code"], name: "idx_analytics_payments_site_referral", where: "(referral_code IS NOT NULL)"
    t.index ["analytics_site_id"], name: "index_analytics_payments_on_analytics_site_id"
  end

  create_table "analytics_sites", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "name"
    t.bigint "shop_id", null: false
    t.string "site_token", null: false
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_analytics_sites_on_domain"
    t.index ["shop_id", "domain"], name: "index_analytics_sites_on_shop_id_and_domain", unique: true
    t.index ["shop_id"], name: "index_analytics_sites_on_shop_id"
    t.index ["site_token"], name: "index_analytics_sites_on_site_token", unique: true
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

  create_table "customer_imports", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "last_cursor"
    t.bigint "shop_id", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "total_created", default: 0
    t.integer "total_fetched", default: 0
    t.integer "total_skipped", default: 0
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_customer_imports_on_shop_id"
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

  create_table "generation_logs", force: :cascade do |t|
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.jsonb "input_context", default: {}
    t.boolean "is_retry", default: false
    t.string "model_used"
    t.string "output_image_url"
    t.text "prompt_text"
    t.integer "quality_score"
    t.bigint "shop_id", null: false
    t.string "surface", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_generation_logs_on_created_at"
    t.index ["shop_id", "surface"], name: "index_generation_logs_on_shop_id_and_surface"
    t.index ["shop_id"], name: "index_generation_logs_on_shop_id"
  end

  create_table "media_assets", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.bigint "shop_id", null: false
    t.string "surface"
    t.datetime "updated_at", null: false
    t.index ["shop_id", "created_at"], name: "index_media_assets_on_shop_id_and_created_at"
    t.index ["shop_id"], name: "index_media_assets_on_shop_id"
  end

  create_table "prompt_templates", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "category"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "surface", null: false
    t.text "template_text", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_prompt_templates_on_key", unique: true
    t.index ["surface", "category"], name: "index_prompt_templates_on_surface_and_category"
  end

  create_table "referral_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.string "referral_code"
    t.bigint "shop_id", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_referral_events_on_created_at"
    t.index ["event_type"], name: "index_referral_events_on_event_type"
    t.index ["shop_id"], name: "index_referral_events_on_shop_id"
    t.index ["source"], name: "index_referral_events_on_source"
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
    t.bigint "shop_id", null: false
    t.string "shopify_discount_id"
    t.string "shopify_order_id"
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_number", null: false
    t.index ["awtomic_subscription_id"], name: "index_referral_rewards_on_awtomic_subscription_id"
    t.index ["referral_id", "shopify_order_id"], name: "index_referral_rewards_on_referral_id_and_shopify_order_id", unique: true
    t.index ["referral_id"], name: "index_referral_rewards_on_referral_id"
    t.index ["shop_id", "code"], name: "index_referral_rewards_on_shop_id_and_code", unique: true
    t.index ["shop_id"], name: "index_referral_rewards_on_shop_id"
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

  create_table "scene_assets", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "mood"
    t.jsonb "tags", default: []
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_scene_assets_on_category"
    t.index ["tags"], name: "index_scene_assets_on_tags", using: :gin
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
    t.string "granted_scopes"
    t.string "klaviyo_api_key"
    t.bigint "shop_id", null: false
    t.string "shopify_access_token"
    t.string "shopify_webhook_secret"
    t.datetime "updated_at", null: false
    t.string "webhook_secret"
    t.index ["shop_id"], name: "index_shop_credentials_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.jsonb "brand_profile", default: {}
    t.datetime "created_at", null: false
    t.datetime "credits_reset_at"
    t.string "domain", null: false
    t.integer "generation_credits_remaining", default: 10
    t.string "name", null: false
    t.jsonb "platform_config", default: {}
    t.string "platform_type", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.string "storefront_url"
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_shops_on_domain", unique: true
    t.index ["platform_type"], name: "index_shops_on_platform_type"
    t.index ["slug"], name: "index_shops_on_slug", unique: true
    t.index ["status"], name: "index_shops_on_status"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analytics_events", "analytics_sites", on_delete: :cascade
  add_foreign_key "analytics_payments", "analytics_sites", on_delete: :cascade
  add_foreign_key "analytics_sites", "shops"
  add_foreign_key "audit_logs", "shops"
  add_foreign_key "customer_imports", "shops"
  add_foreign_key "discount_configs", "shops"
  add_foreign_key "discount_generations", "shared_discounts"
  add_foreign_key "generation_logs", "shops"
  add_foreign_key "media_assets", "shops"
  add_foreign_key "referral_events", "shops"
  add_foreign_key "referral_rewards", "referrals"
  add_foreign_key "referral_rewards", "shops"
  add_foreign_key "referrals", "discount_generations"
  add_foreign_key "referrals", "shops"
  add_foreign_key "shared_discounts", "shops"
  add_foreign_key "shop_credentials", "shops"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "shops"
end
