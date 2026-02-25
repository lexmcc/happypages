FactoryBot.define do
  factory :specs_client, class: "Specs::Client" do
    organisation
    email { Faker::Internet.unique.email }

    trait :with_password do
      password { "SecurePass123!" }
    end

    trait :invited do
      invite_token { SecureRandom.urlsafe_base64(32) }
      invite_sent_at { Time.current }
    end

    trait :accepted do
      password { "SecurePass123!" }
      invite_accepted_at { Time.current }
      last_sign_in_at { Time.current }
    end
  end
end
