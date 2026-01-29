class ExpandSharedDiscountsForGroups < ActiveRecord::Migration[8.0]
  def change
    change_table :shared_discounts do |t|
      t.string :name

      # Base rules
      t.string :referred_discount_type
      t.string :referred_discount_value
      t.string :referrer_reward_type
      t.string :referrer_reward_value

      # Override rules (temporary boost)
      t.string :override_referred_type
      t.string :override_referred_value
      t.string :override_reward_type
      t.string :override_reward_value
      t.datetime :override_starts_at
      t.datetime :override_ends_at
      t.boolean :override_applied, default: false

      t.boolean :is_active, default: false
    end

    # Remove unique constraint on discount_type to allow multiple groups
    remove_index :shared_discounts, :discount_type
  end
end
