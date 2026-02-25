require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:specs_clients).class_name("Specs::Client").dependent(:destroy) }
    it { is_expected.to have_many(:specs_projects).class_name("Specs::Project").dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates slug uniqueness" do
      create(:organisation, slug: "test-org")
      org = build(:organisation, slug: "test-org")
      expect(org).not_to be_valid
    end
  end

  describe "slug generation" do
    it "auto-generates slug from name" do
      org = create(:organisation, name: "My Company")
      expect(org.slug).to eq("my-company")
    end

    it "handles duplicate slugs with counter" do
      create(:organisation, name: "Acme Corp")
      org = create(:organisation, name: "Acme Corp")
      expect(org.slug).to eq("acme-corp-1")
    end

    it "does not overwrite existing slug" do
      org = create(:organisation, name: "Test", slug: "custom-slug")
      expect(org.slug).to eq("custom-slug")
    end
  end
end
