class ItemsGroupsController < ApplicationController
  before_action :set_items_group, only: %i[ show edit update destroy ]

  # GET /items_groups or /items_groups.json
  def index
    @items_groups = ItemsGroup.all
    @distinct_names = Item.select(:name).distinct.pluck(:name)
  end

  # GET /items_groups/1 or /items_groups/1.json
  def show
    @template = Template.find_by(id: @items_group.template_id.to_s)
  end

  # GET /items_groups/new
  def new
    @items_group = ItemsGroup.new
    @template = Template.all
  end

  # GET /items_groups/1/edit
  def edit
    @template = Template.all
    @template_select = Template.find_by(id: @items_group.template_id.to_s)
  end

  # POST /items_groups or /items_groups.json
  def create
    @template = Template.all
    Rails.logger.debug("params: #{params.inspect}")
    
    # Templateの選択
    title_template = params[:items_group][:title_template]
    selected_template = Template.find_by(name: title_template)
    unless selected_template
      flash[:alert] = "Selected template not found."
      @items_group = ItemsGroup.new 
      return render :new, status: :unprocessable_entity
    end
    
    temp_code = selected_template["content"]
    basename = selected_template["basename"]
    unless params[:items_group][:dsl_info]
      flash[:alert] = "Selected spreadsheet not found."
      @items_group = ItemsGroup.new 
      return render :new, status: :unprocessable_entity
    end
    filename = params[:items_group][:dsl_info].original_filename
    tempfile = params[:items_group][:dsl_info].tempfile
    
    # ItemsGroupの作成
    @items_group = ItemsGroup.new(name: params[:items_group][:name], template_id: selected_template["id"])
    
    if @items_group.save
      items_group_id = @items_group.id
    else
      Rails.logger.error "ItemsGroup validation failed: #{@items_group.errors.full_messages.to_sentence}"
      return render :new, status: :unprocessable_entity
    end
    
    tempfile_path = "#{Dir.pwd}/db/#{filename}"
    
    begin
      # 一時ファイルの保存
      File.open(tempfile_path, 'wb') do |file|
        file.write(tempfile.read)
      end
      
      exporter = ItemsExporter.new
      doc = Roo::Excelx.new(tempfile_path)
      doc.default_sheet = doc.sheets.first
      
      headers = {}
      (doc.first_column..doc.last_column).each do |col|
        headers[col] = doc.cell(doc.first_row, col)
      end
      
      ((doc.first_row + 1)..doc.last_row).each do |row|
        row_data = {}
        headers.keys.each do |col|
          value = doc.cell(row, col)
          row_data[headers[col]] = value
        end
        
        exporter.post_items(row_data, temp_code, basename)
        
        @item = Item.new(name: row_data['itemID'], dsl_info: row_data.to_json, items_group_id: items_group_id)
        unless @item.save
          Rails.logger.error("Failed to save item: #{@item.errors.full_messages.to_sentence}")
          flash[:alert] = "Failed to save some items."
          next
        end
      end
      
      redirect_to items_group_url(@items_group)
    rescue => e
      Rails.logger.error "Error processing the file: #{e.message}"
      flash[:alert] = "An error occurred while processing the file."
      render :new, status: :unprocessable_entity
    ensure
      File.delete(tempfile_path) if File.exist?(tempfile_path)
    end
  end
  

  # PATCH/PUT /items_groups/1 or /items_groups/1.json
  def update
    selected_template = Template.find_by(id: @items_group.template_id.to_s)
    temp_code = selected_template["content"]
    basename = selected_template["basename"]
    # パラメータから更新情報を取得
    updated_dsl_info = params[:items_group][:dsl_info]
    Rails.logger.debug("DSL Info: #{updated_dsl_info.inspect}")
    
    @items_group = ItemsGroup.update(template_id: selected_template["id"])

    exporter = ItemsExporter.new
    # items_groupのIDリストを取得
    @document_ids = @item.pluck(:id)
    # 各アイテムのDSL情報を更新
    @document_ids.each_with_index do |id, index|
      # 更新するアイテムを取得
      item = Item.find(id)

      # 更新情報をJSON形式に変換
      new_dsl_info = updated_dsl_info[index.to_s].to_json

      # アイテムを更新
      if item.update(dsl_info: new_dsl_info)
        Rails.logger.debug("Item #{id} updated successfully.")
      else
        Rails.logger.error("Failed to update item #{id}: #{item.errors.full_messages.join(", ")}")
      end
      row_data = item["dsl_info"]
      exporter.edit_items(row_data, temp_code, basename)
    end
  
    # 更新後のリダイレクトまたはレンダリング
    respond_to do |format|
      format.html { redirect_to items_groups_path, notice: 'Items were successfully updated.' }
      format.json { render :show, status: :ok, location: @items_group }
    end
  end

  # DELETE /items_groups/1 or /items_groups/1.json
  def destroy
    items = @item
    exporter = ItemsExporter.new
    # 各レコードを1つずつ削除
    items.each do |item|
      template = Template.find_by(id: @items_group.template_id.to_s)
      row_data = item["dsl_info"]
      basename = template["basename"]
      exporter.delete_items(row_data, basename)
      item.destroy
    end
    @items_group.destroy!
    redirect_to items_groups_path, notice: "Items was successfully removed." 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_items_group
      # @distinct_names = Item.select(:name).distinct.pluck(:name)
      # @items_group = Item.where(name: @distinct_names[params[:id].to_i - 1])
      @items_group = ItemsGroup.find(params[:id])
      @item = Item.where(items_group_id: @items_group.id)
      @document_ids = @item.pluck(:id)
      @combined_dsl_info = @item.map { |item| JSON.parse(item.dsl_info) }
    end    

    # Only allow a list of trusted parameters through.
    def items_group_params
      params.require(:items_group).permit(:name, :template_id)
    end
end
