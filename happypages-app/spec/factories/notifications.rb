FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :notifiable, factory: :specs_session
    action { "spec_completed" }
    data { { project_name: "Test Project" } }

    trait :unread do
      read_at { nil }
    end

    trait :read do
      read_at { Time.current }
    end

    trait :card_review do
      action { "card_review" }
      association :notifiable, factory: :specs_card
    end

    trait :turn_limit do
      action { "turn_limit_approaching" }
    end
  end
end
