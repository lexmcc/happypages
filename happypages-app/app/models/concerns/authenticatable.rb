module Authenticatable
  extend ActiveSupport::Concern

  included do
    has_secure_password validations: false

    validates :password, length: { minimum: 8 }, if: -> { password.present? }
  end

  def invite_pending?
    invite_token.present? && invite_accepted_at.nil?
  end

  def invite_accepted?
    invite_accepted_at.present?
  end
end
