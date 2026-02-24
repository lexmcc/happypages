require "rails_helper"

RSpec.describe Specs::Project, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shop) }
    it { is_expected.to have_many(:sessions).class_name("Specs::Session").with_foreign_key(:specs_project_id).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "table name" do
    it "uses specs_projects table" do
      expect(described_class.table_name).to eq("specs_projects")
    end
  end
end
