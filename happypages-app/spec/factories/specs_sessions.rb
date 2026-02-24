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

    trait :with_outputs do
      status { "completed" }
      client_brief do
        {
          "title" => "Test Project",
          "goal" => "Build an e-commerce checkout flow",
          "sections" => [
            { "heading" => "Background", "content" => "The client needs a modern checkout." },
            { "heading" => "What We're Building", "content" => "A two-step checkout with Stripe." }
          ]
        }
      end
      team_spec do
        {
          "title" => "Test Project",
          "goal" => "Build an e-commerce checkout flow",
          "approach" => "Rails + Stimulus + Stripe Elements",
          "chunks" => [
            {
              "title" => "Cart summary component",
              "description" => "Renders line items with quantity controls.",
              "acceptance_criteria" => ["Given items in cart, when page loads, then all items display with prices"],
              "dependencies" => [],
              "has_ui" => true
            },
            {
              "title" => "Stripe integration",
              "description" => "Payment intent creation and confirmation.",
              "acceptance_criteria" => ["Given valid card, when user submits, then payment succeeds"],
              "dependencies" => ["Cart summary component"],
              "has_ui" => true
            }
          ],
          "tech_notes" => ["Use Stripe Elements for PCI compliance"],
          "design_tokens" => {
            "colors" => { "primary" => "#ff584d", "background" => "#f4f4f0" },
            "typography" => { "body" => { "family" => "Inter", "size" => "16px" } },
            "spacing" => { "base" => "8px" },
            "effects" => { "shadow" => "0 2px 4px rgba(0,0,0,0.1)" }
          },
          "open_questions" => ["Should we support Apple Pay?"]
        }
      end
    end
  end
end
