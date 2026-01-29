class ShopCredential < ApplicationRecord
  belongs_to :shop

  # Encrypt all sensitive tokens
  encrypts :shopify_access_token
  encrypts :api_key
  encrypts :awtomic_api_key
  encrypts :klaviyo_api_key
end
