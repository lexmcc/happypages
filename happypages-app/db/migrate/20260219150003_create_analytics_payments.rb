class CreateAnalyticsPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_payments do |t|
      t.references :analytics_site, null: false, foreign_key: true
      t.string :visitor_id, null: false
      t.string :session_id
      t.string :order_id
      t.integer :amount_cents, null: false
      t.string :currency, limit: 3, default: "GBP"
      t.string :referral_code
      t.jsonb :properties, null: false, default: {}

      t.timestamps
    end

    add_index :analytics_payments, [:analytics_site_id, :created_at]
    add_index :analytics_payments, [:analytics_site_id, :referral_code], where: "referral_code IS NOT NULL", name: "idx_analytics_payments_site_referral"
    add_index :analytics_payments, [:analytics_site_id, :order_id], unique: true, name: "idx_analytics_payments_site_order"
  end
end
