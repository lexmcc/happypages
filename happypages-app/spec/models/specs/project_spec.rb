require "rails_helper"

RSpec.describe Specs::Project, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shop).optional }
    it { is_expected.to belong_to(:organisation).optional }
    it { is_expected.to have_many(:sessions).class_name("Specs::Session").with_foreign_key(:specs_project_id).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "requires either shop or organisation" do
      project = build(:specs_project, shop: nil, organisation: nil)
      expect(project).not_to be_valid
      expect(project.errors[:base]).to include("must belong to a shop or an organisation")
    end

    it "disallows both shop and organisation" do
      project = build(:specs_project, shop: create(:shop), organisation: create(:organisation))
      expect(project).not_to be_valid
      expect(project.errors[:base]).to include("cannot belong to both a shop and an organisation")
    end

    it "is valid with only a shop" do
      project = build(:specs_project, shop: create(:shop), organisation: nil)
      expect(project).to be_valid
    end

    it "is valid with only an organisation" do
      project = build(:specs_project, shop: nil, organisation: create(:organisation))
      expect(project).to be_valid
    end
  end

  describe "table name" do
    it "uses specs_projects table" do
      expect(described_class.table_name).to eq("specs_projects")
    end
  end
end
