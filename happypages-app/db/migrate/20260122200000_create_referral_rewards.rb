class CreateReferralRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :referral_rewards do |t|
      t.references :referral, null: false, foreign_key: true
      t.string :code, null: false
      t.string :shopify_discount_id
      t.string :status, null: false, default: "created"
      t.string :awtomic_subscription_id
      t.string :awtomic_customer_id
      t.integer :usage_number, null: false
      t.datetime :applied_at
      t.datetime :consumed_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :referral_rewards, :code, unique: true
    add_index :referral_rewards, :status
    add_index :referral_rewards, :awtomic_subscription_id
    add_index :referral_rewards, [ :status, :expires_at ]
  end
end
