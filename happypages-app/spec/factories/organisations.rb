FactoryBot.define do
  factory :organisation do
    name { "Test Organisation" }

    trait :with_slug do
      slug { "test-org" }
    end
  end
end
