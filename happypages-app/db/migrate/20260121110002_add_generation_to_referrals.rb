class AddGenerationToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_reference :referrals, :discount_generation, foreign_key: true
  end
end
