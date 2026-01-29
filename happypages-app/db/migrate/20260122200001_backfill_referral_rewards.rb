class BackfillReferralRewards < ActiveRecord::Migration[8.1]
  def up
    # Convert existing referrer_reward_codes arrays to ReferralReward records
    execute <<-SQL
      INSERT INTO referral_rewards (referral_id, code, status, usage_number, expires_at, created_at, updated_at)
      SELECT
        r.id,
        unnest(r.referrer_reward_codes),
        'created',
        row_number() OVER (PARTITION BY r.id ORDER BY unnest(r.referrer_reward_codes)),
        NOW() + INTERVAL '30 days',
        NOW(),
        NOW()
      FROM referrals r
      WHERE array_length(r.referrer_reward_codes, 1) > 0
      ON CONFLICT (code) DO NOTHING;
    SQL

    # Mark rewards as applied if subscription_applied_at is set on the referral
    execute <<-SQL
      UPDATE referral_rewards rr
      SET status = 'applied_to_subscription',
          applied_at = r.subscription_applied_at
      FROM referrals r
      WHERE rr.referral_id = r.id
        AND r.subscription_applied_at IS NOT NULL
        AND rr.status = 'created';
    SQL
  end

  def down
    # Remove all referral_rewards that were backfilled
    execute <<-SQL
      DELETE FROM referral_rewards
      WHERE shopify_discount_id IS NULL;
    SQL
  end
end
