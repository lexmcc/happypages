FactoryBot.define do
  factory :specs_card, class: "Specs::Card" do
    association :project, factory: :specs_project
    association :session, factory: :specs_session
    title { "Test Card" }
    description { "A test delivery card" }
    acceptance_criteria { ["It works"] }
    has_ui { false }
    dependencies { [] }
    status { "backlog" }
    position { 0 }

    trait :in_progress do
      status { "in_progress" }
    end

    trait :review do
      status { "review" }
    end

    trait :done do
      status { "done" }
    end

    trait :manual do
      session { nil }
      chunk_index { nil }
    end
  end
end
