FactoryBot.define do
  factory :shop_feature do
    shop
    feature { "referrals" }
    status { "active" }
    activated_at { Time.current }

    trait :locked do
      status { "locked" }
    end

    trait :trial do
      status { "trial" }
    end

    trait :analytics do
      feature { "analytics" }
    end
  end
end
