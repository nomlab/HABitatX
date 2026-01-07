class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]
  # GET /items or /items.json
  def index
    @items = Item.all
  end

  # GET /items/1 or /items/1.json
  def show
    @template = Template.find_by(id: @item.template_id)
  end

  # GET /items/new
  def new
    @item = Item.new
    @template = Template.all
  end

  # GET /items/1/edit
  def edit
    @template = Template.all
  end

  # POST /items or /items.json
  def create
    template = nil
    uploaded_file = nil
    
    begin
      template = Template.find_by(name: params[:item][:title_template])
      name = params[:item][:name]
      
      raise "Template not found" if template.nil?
      raise "Name is missing" if name.blank?

      uploaded_file = params[:item][:dsl_info]
      raise "File not selected" if uploaded_file.nil?

      save_excel_file(uploaded_file.original_filename, uploaded_file.tempfile)
      puts Rails.root.join("excel/#{uploaded_file.original_filename}")

      habdsl = Habdsl::SheetParser.parse(
        input_code: template.content, 
        excel_path: Rails.root.join("excel/#{uploaded_file.original_filename}").to_s
      )
      table = habdsl.table
      dsl = habdsl.dsl

      file_path = "#{ENV['OPENHAB_PATH']}/items/#{template.basename}_#{name}.items"
      raise "File_path has already existed" if File.exist?(file_path)

      @item = Item.new(name: name, dsl_info: table.to_json, template_id: template.id)

      respond_to do |format|
        if @item.save
          post_items(dsl, file_path)
          cleanup_excel_file(uploaded_file.original_filename)
          format.html { redirect_to @item, notice: "アイテムが正常に作成されました。" }
          format.json { render :show, status: :created, location: @item }
        else
          cleanup_excel_file(uploaded_file.original_filename)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @item.errors, status: :unprocessable_entity }
        end
      end

    rescue => e
      handle_create_error(e, uploaded_file)
    end
  end

  # PATCH/PUT /items/1 or /items/1.json
  def update
    begin
      template = Template.find_by(name: params[:item][:title_template])
      name = params[:item][:name]
      
      raise "Template not found" if template.nil?
      raise "Name is missing" if name.blank?

      uploaded_json = params[:item][:dsl_info]

      habdsl = Habdsl::JsonParser.parse(input_code: template.content, json_code: uploaded_json)
      table = habdsl.table
      dsl = habdsl.dsl

      file_path = "#{ENV['OPENHAB_PATH']}/items/#{template.basename}_#{name}.items"

      respond_to do |format|
        if @item.update(name: name, dsl_info: table.to_json, template_id: template.id)
          post_items(dsl, file_path)
          format.html { redirect_to @item, notice: "アイテムが正常に更新されました。" }
          format.json { render :show, status: :ok, location: @item }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @item.errors, status: :unprocessable_entity }
        end
      end

    rescue => e
      handle_update_error(e)
    end
  end

  # DELETE /items/1 or /items/1.json
  def destroy
    begin
      template = Template.find_by(id: @item.template_id)
      name = @item.name
      
      if template && name.present?
        file_path = "#{ENV['OPENHAB_PATH']}/items/#{template.basename}_#{name}.items"
        delete_items(file_path) if File.exist?(file_path)
      end
      
      @item.destroy!

      respond_to do |format|
        format.html { redirect_to items_path, status: :see_other, notice: "アイテムが正常に削除されました。" }
        format.json { head :no_content }
      end

    rescue => e
      Rails.logger.error "Failed to destroy item: #{e.message}"
      flash[:alert] = "アイテムの削除中にエラーが発生しました: #{e.message}"
      redirect_to items_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.expect(item: [ :name, :dsl_info, :template_id ])
    end

    def save_excel_file(file_name, file_content)
      dir = Rails.root.join("excel")
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      tempfile_path = dir.join(file_name)
      file_content.rewind  # 安全のため、読み込みポインタを先頭に戻す
      File.open(tempfile_path, "wb") do |file|
        file.write(file_content.read)
      end
      tempfile_path.to_s
    end

    def post_items(dsl, file_path)
      # ファイルに書き込む
      File.open(file_path, "w") do |file|
        file.puts dsl
      end
    end

    def delete_items(file_path)
      File.delete(file_path) if File.exist?(file_path)
    end

    # ファイルクリーンアップのヘルパーメソッド
    def cleanup_excel_file(filename)
      return unless filename.present?
      
      path = Rails.root.join("excel", filename)
      File.delete(path) if File.exist?(path)
    rescue => e
      Rails.logger.error "Failed to cleanup excel file #{filename}: #{e.message}"
    end

    # 作成時のエラーハンドリング
    def handle_create_error(error, uploaded_file)
      cleanup_excel_file(uploaded_file&.original_filename)
      
      error_message = case error
      when NoMethodError
        if error.message.include?("undefined method `original_filename' for nil")
          "ファイルが選択されていません"
        else
          "予期しないエラーが発生しました"
        end
      when RuntimeError
        case error.message
        when "Template not found"
          "テンプレートが見つかりません"
        when "Name is missing"
          "名前が入力されていません"
        when "File not selected"
          "ファイルが選択されていません"
        when "File_path has already existed"
          "既に同名のopenHAB設定DSLファイルが存在します"
        else
          error.message
        end
      when Habdsl::BaseParser::DSLValidationError
        prefix = "Runtime error during DSL evaluation: RuntimeError - "
        if error.message.start_with?(prefix)
          error.message[prefix.length..-1]
        else
          error.message
        end
      else
        "#{error.class}: #{error.message}"
      end

      flash[:alert] = "エラーが発生しました: #{error_message}"
      Rails.logger.error "Item creation failed: #{error.class} - #{error.message}"
      redirect_to new_item_path
    end

    # 更新時のエラーハンドリング
    def handle_update_error(error)
      error_message = case error
      when RuntimeError
        case error.message
        when "Template not found"
          "テンプレートが見つかりません"
        when "Name is missing"
          "名前が入力されていません"
        else
          error.message
        end
      when Habdsl::BaseParser::DSLValidationError
        prefix = "Runtime error during DSL evaluation: RuntimeError - "
        if error.message.start_with?(prefix)
          error.message[prefix.length..-1]
        else
          error.message
        end
      else
        "#{error.class}: #{error.message}"
      end

      flash[:alert] = "エラーが発生しました: #{error_message}"
      Rails.logger.error "Item update failed: #{error.class} - #{error.message}"
      redirect_to edit_item_path(@item)
    end
end
