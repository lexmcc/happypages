FactoryBot.define do
  factory :specs_project, class: "Specs::Project" do
    shop
    name { "Test Project" }

    trait :with_briefing do
      context_briefing { "We need a checkout redesign for our Shopify store." }
    end

    trait :org_scoped do
      shop { nil }
      organisation
    end
  end
end
