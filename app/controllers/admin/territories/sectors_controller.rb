class Admin::Territories::SectorsController < Admin::Territories::BaseController
  before_action :set_sector, only: %i[show edit update destroy]
  before_action :authorize_sector, only: %i[show edit update destroy]

  def index
    @sectors = policy_scope(Sector)
      .where(territory: current_territory)
      .includes(:attributions)
      .order_by_name
    @sectors = @sectors.where(attributions: { organisation: params[:organisation_id] }) if params[:organisation_id].present?
    @sectors = @sectors.page(params[:page]) unless params[:view] == "map"
    render :index_map if params[:view] == "map"
  end

  def new
    @sector = Sector.new(territory: current_territory)
    authorize @sector
  end

  def create
    @sector = Sector.new(**sector_params, territory: current_territory)
    authorize @sector
    if @sector.save
      if params[:commit] == I18n.t("helpers.submit.create")
        redirect_to admin_territory_sector_path(current_territory, @sector)
      else
        redirect_to new_admin_territory_sector_path(current_territory), flash: { success: t(".created", sector: @sector.name) }
      end
    else
      render :new
    end
  end

  def show
    @zones = @sector.zones.order(updated_at: :desc).page(params[:page])
  end

  def edit; end

  def update
    @sector.assign_attributes(**sector_params)
    if @sector.save
      redirect_to admin_territory_sector_path(current_territory, @sector), flash: { success: t(".updated") }
    else
      render :edit
    end
  end

  def destroy
    if @sector.destroy
      redirect_to admin_territory_sectors_path(current_territory), flash: { success: t(".deleted") }
    else
      redirect_to admin_territory_sectors_path(current_territory), flash: { error: t(".delete_error") }
    end
  end

  private

  def set_sector
    @sector = Sector.find(params[:id])
  end

  def authorize_sector
    authorize @sector
  end

  def sector_params
    params.require(:sector).permit(:territory_id, :name, :human_id)
  end
end
