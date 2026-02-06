class AuditLog < ApplicationRecord
  belongs_to :shop, optional: true

  ACTIONS = %w[
    view create update delete export
    data_request customer_redact shop_redact
    webhook_received config_access
  ].freeze

  ACTORS = %w[webhook admin system customer].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :actor, presence: true, inclusion: { in: ACTORS }

  scope :for_shop, ->(shop) { where(shop: shop) }
  scope :compliance, -> { where(action: %w[data_request customer_redact shop_redact]) }
  scope :recent, -> { order(created_at: :desc) }

  def self.log(action:, actor:, shop: nil, resource: nil, actor_ip: nil, actor_identifier: nil, details: {})
    create!(
      shop: shop,
      action: action,
      actor: actor,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      actor_ip: actor_ip,
      actor_identifier: actor_identifier,
      details: details
    )
  end
end
