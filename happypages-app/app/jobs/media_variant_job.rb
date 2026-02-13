class MediaVariantJob < ApplicationJob
  def perform(media_asset_id)
    asset = MediaAsset.find(media_asset_id)
    asset.thumbnail_variant.processed
    asset.referral_banner_variant.processed
    asset.extension_banner_variant.processed
  end
end
