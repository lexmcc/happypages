module Specs
  class Client < ApplicationRecord
    self.table_name = "specs_clients"

    include Authenticatable

    belongs_to :organisation

    validates :email, presence: true, uniqueness: { scope: :organisation_id }
    validates :slack_user_id, uniqueness: { scope: :organisation_id }, allow_nil: true
  end
end
