class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]

  # GET /items or /items.json
  def index
    @items = Item.all
  end

  # GET /items/1 or /items/1.json
  def show
    @template = Template.all
    @temp = ItemsGroup.find(@item.items_group_id)
    @template_id = Template.find(@temp.template_id.to_s)
  end

  # GET /items/new
  def new
    @item = Item.new
    @items_group = ItemsGroup.all
  end

  # GET /items/1/edit
  def edit
    @template = Template.all
    @dsl_info_hash = JSON.parse(@item.dsl_info)
  end

  # POST /items or /items.json
  def create
    @items_group = ItemsGroup.all
    title_items_group = params[:item][:title_items_group]
    selected_items_group = ItemsGroup.find_by(name: title_items_group)

    unless selected_items_group
      flash[:alert] = "You have not selected Items Group."
      @item = Item.new 
      return render :new, status: :unprocessable_entity
    end
    selected_template = Template.find_by(id: selected_items_group["template_id"])
    temp_code = selected_template["content"]
    basename = selected_template["basename"]
  
    @item = Item.new(name: params[:item][:name], dsl_info: params[:item][:dsl_info], items_group_id: selected_items_group["id"])
  
    respond_to do |format|
      if @item.save
        row_data = JSON.parse(params[:item][:dsl_info])
        exporter = ItemsExporter.new
        exporter.post_items(row_data, temp_code, basename)
        format.html { redirect_to item_url(@item), notice: "Item was successfully created." }
        format.json { render :show, status: :created, location: @item }
      else
        Rails.logger.error "Item validation failed: #{@item.errors.full_messages.to_sentence}"
        return render :new, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /items/1 or /items/1.json
  # app/controllers/items_controller.rb
  def update
    temp_code = @selected_template["content"]
    basename = @selected_template["basename"]
    exporter = ItemsExporter.new
    # パラメータから dsl_info を取得
    updated_dsl_info = params[:dsl_info]

    if @item.update(dsl_info: updated_dsl_info.to_json)
      redirect_to @item, notice: 'Item was successfully updated.'
    else
      render :edit
    end
    row_data = @item["dsl_info"]
    exporter.edit_items(row_data, temp_code, basename)
  end


  # DELETE /items/1 or /items/1.json
  def destroy
    exporter = ItemsExporter.new
    basename = @selected_template["basename"]
    row_data = @item["dsl_info"]
    exporter.delete_items(row_data, basename)
    @item.destroy!

    respond_to do |format|
      format.html { redirect_to items_url, notice: "Item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
      @selected_items_group = ItemsGroup.find_by(id: @item.items_group_id)
      @selected_template = Template.find_by(id: @selected_items_group["template_id"])
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.require(:item).permit(:name, :dsl_info, :template_id)
    end
end

