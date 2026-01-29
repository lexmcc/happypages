class CreateReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :referrals do |t|
      t.string :first_name, null: false
      t.string :email, null: false
      t.string :referral_code, null: false
      t.string :shopify_discount_id
      t.integer :usage_count, default: 0

      t.timestamps
    end

    add_index :referrals, :referral_code, unique: true
    add_index :referrals, :email
  end
end
