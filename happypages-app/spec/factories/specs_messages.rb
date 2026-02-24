FactoryBot.define do
  factory :specs_message, class: "Specs::Message" do
    association :session, factory: :specs_session
    role { "user" }
    content { "This is a test message" }
    turn_number { 1 }

    trait :assistant do
      role { "assistant" }
      model_used { "claude-sonnet-4-5-20250929" }
    end

    trait :with_question do
      role { "assistant" }
      tool_name { "ask_question" }
      tool_calls { { "question" => "What type of project?", "options" => [{ "label" => "Web app", "description" => "A web application" }] } }
    end
  end
end
