class Superadmin::SceneAssetsController < Superadmin::BaseController
  before_action :set_scene_asset, only: [ :edit, :update, :destroy ]

  def index
    @scene_assets = SceneAsset.order(created_at: :desc)
    @scene_assets = @scene_assets.for_category(params[:category]) if params[:category].present?
  end

  def new
    @scene_asset = SceneAsset.new
  end

  def create
    @scene_asset = SceneAsset.new(scene_asset_params)

    if params[:scene_asset][:file].present?
      @scene_asset.file.attach(params[:scene_asset][:file])
    end

    if @scene_asset.save
      redirect_to superadmin_scene_assets_path, notice: "Scene asset created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:scene_asset][:file].present?
      @scene_asset.file.attach(params[:scene_asset][:file])
    end

    if @scene_asset.update(scene_asset_params)
      redirect_to superadmin_scene_assets_path, notice: "Scene asset updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scene_asset.file.purge if @scene_asset.file.attached?
    @scene_asset.destroy!
    redirect_to superadmin_scene_assets_path, notice: "Scene asset deleted"
  end

  private

  def set_scene_asset
    @scene_asset = SceneAsset.find(params[:id])
  end

  def scene_asset_params
    params.require(:scene_asset).permit(:category, :mood, :description, :tag_list)
  end
end
