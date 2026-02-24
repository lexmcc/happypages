module Specs
  class Project < ApplicationRecord
    self.table_name = "specs_projects"

    belongs_to :shop
    has_many :sessions, class_name: "Specs::Session", foreign_key: :specs_project_id, dependent: :destroy

    validates :name, presence: true
  end
end
