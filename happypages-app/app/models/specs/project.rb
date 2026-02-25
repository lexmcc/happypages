module Specs
  class Project < ApplicationRecord
    self.table_name = "specs_projects"

    belongs_to :shop, optional: true
    belongs_to :organisation, optional: true
    has_many :sessions, class_name: "Specs::Session", foreign_key: :specs_project_id, dependent: :destroy
    has_many :cards, class_name: "Specs::Card", foreign_key: :specs_project_id, dependent: :destroy

    validates :name, presence: true
    validate :must_belong_to_shop_or_organisation

    private

    def must_belong_to_shop_or_organisation
      if shop_id.blank? && organisation_id.blank?
        errors.add(:base, "must belong to a shop or an organisation")
      elsif shop_id.present? && organisation_id.present?
        errors.add(:base, "cannot belong to both a shop and an organisation")
      end
    end
  end
end
