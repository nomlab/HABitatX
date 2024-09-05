class TemplatesController < ApplicationController
  before_action :check_session_expiry, only: [:show, :new, :edit, :destroy]
  before_action :require_login, only: [:show, :new, :edit, :destroy]
  before_action :require_admin, only: [:new, :edit, :destroy]
  before_action :set_template, only: %i[ show edit update destroy ]

  # GET /templates or /templates.json
  def index
    @templates = Template.all
    case params[:sort]
    when 'things'
      @templates = @templates.where(filetype: 'things')
    when 'items'
      @templates = @templates.where(filetype: 'items')
    when 'rules'
      @templates = @templates.where(filetype: 'rules')
    end
  end

  # GET /templates/1 or /templates/1.json
  def show
  end

  # GET /templates/new
  def new
    @template = Template.new
  end

  # GET /templates/1/edit
  def edit
  end

  # POST /templates or /templates.json
  def create
    @template = Template.new(template_params)

    respond_to do |format|
      if @template.save
        format.html { redirect_to template_url(@template), notice: "Template was successfully created." }
        format.json { render :show, status: :created, location: @template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /templates/1 or /templates/1.json
  def update
    respond_to do |format|
      if @template.update(template_params)
        format.html { redirect_to template_url(@template), notice: "Template was successfully updated." }
        format.json { render :show, status: :ok, location: @template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /templates/1 or /templates/1.json
  def destroy
    @template.destroy!

    respond_to do |format|
      format.html { redirect_to templates_url, notice: "Template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_template
      @template = Template.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def template_params
      params.require(:template).permit(:name, :basename, :filetype, :content)
    end

    def require_login
      unless session[:user]
        redirect_to login_path, alert: 'ログインが必要です。'
      end
    end
  
    def require_admin
      unless session[:user] && session[:user]['admin']
        redirect_to templates_path, notice: 'このアクションを実行する権限がありません。'
      end
    end

    def check_session_expiry
      if session[:user] && session[:user]['expires_at'] && session[:user]['expires_at'] < Time.current
        # セッションの有効期限が切れている場合、ログアウト処理を実行
        reset_session
        redirect_to login_path, alert: 'セッションが期限切れになりました。再度ログインしてください。'
      end
    end
end