FactoryBot.define do
  factory :specs_session, class: "Specs::Session" do
    association :project, factory: :specs_project
    shop { project.shop }

    trait :with_user do
      user { association :user, shop: shop }
    end

    trait :completed do
      status { "completed" }
    end

    trait :in_generate_phase do
      phase { "generate" }
      turns_used { 16 }
    end
  end
end
