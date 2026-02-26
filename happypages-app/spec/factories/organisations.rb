FactoryBot.define do
  factory :organisation do
    name { "Test Organisation" }

    trait :with_slug do
      slug { "test-org" }
    end

    trait :with_slack do
      slack_team_id { "T#{SecureRandom.hex(5).upcase}" }
      slack_bot_token { "xoxb-test-#{SecureRandom.hex(10)}" }
      slack_app_id { "A#{SecureRandom.hex(5).upcase}" }
    end
  end
end
