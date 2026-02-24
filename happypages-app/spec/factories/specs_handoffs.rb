FactoryBot.define do
  factory :specs_handoff, class: "Specs::Handoff" do
    association :session, factory: :specs_session
    from_name { "admin@example.com" }
    reason { "Client needs to answer brand questions" }
    summary { "Covered technical architecture and data model. Need brand input." }
    suggested_questions { ["What are your brand colors?", "What tone of voice do you want?"] }
    turn_number { 3 }

    trait :with_invite do
      to_name { "Client Person" }
      to_role { "client" }
      invite_token { SecureRandom.urlsafe_base64(32) }
      invite_expires_at { 7.days.from_now }
    end

    trait :accepted do
      with_invite
      invite_accepted_at { Time.current }
    end

    trait :internal do
      to_user { association :user, shop: session.shop }
      to_name { "teammate@example.com" }
      to_role { "member" }
      invite_accepted_at { Time.current }
    end

    trait :expired do
      with_invite
      invite_expires_at { 1.day.ago }
    end
  end
end
