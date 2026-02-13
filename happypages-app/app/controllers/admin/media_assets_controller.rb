class Admin::MediaAssetsController < Admin::BaseController
  MAX_ASSETS_PER_SHOP = 50

  def index
    @assets = Current.shop.media_assets.recent.with_attached_file

    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json: @assets.map { |asset| serialize(asset) } }
    end
  end

  def create
    file = params[:file]

    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end

    if Current.shop.media_assets.count >= MAX_ASSETS_PER_SHOP
      return render json: { error: "You can upload up to #{MAX_ASSETS_PER_SHOP} images. Delete some to make room." }, status: :unprocessable_entity
    end

    asset = Current.shop.media_assets.build(
      filename: file.original_filename,
      content_type: file.content_type,
      byte_size: file.size
    )

    unless asset.valid?
      return render json: { error: asset.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    asset.file.attach(file)
    asset.save!

    render json: serialize(asset), status: :created
  end

  def destroy
    asset = Current.shop.media_assets.find(params[:id])
    asset.destroy!
    head :no_content
  end

  private

  def serialize(asset)
    {
      id: asset.id,
      filename: asset.filename,
      content_type: asset.content_type,
      byte_size: asset.byte_size,
      created_at: asset.created_at,
      thumbnail_url: url_for(asset.thumbnail_variant),
      referral_banner_url: url_for(asset.referral_banner_variant),
      extension_banner_url: url_for(asset.extension_banner_variant)
    }
  end
end
