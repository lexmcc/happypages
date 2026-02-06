# Configure Active Record Encryption from environment variables
# Required for encrypting ShopCredential sensitive fields

if ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].present?
  Rails.application.config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
  Rails.application.config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
end

# Allow reading plaintext data from columns that now have `encrypts`
# Required during transition while existing records are re-encrypted
Rails.application.config.active_record.encryption.support_unencrypted_data = true
