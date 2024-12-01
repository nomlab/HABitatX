class UsersController < ApplicationController
  before_action :correct_user, only: [:edit, :destroy]
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    def correct_user
      @user = User.find(params[:id])
    
      if @current_user == @user && @current_user.admin?
          # 管理者が自分自身を編集する場合 → 編集を許可
          # 処理を続行
      elsif @current_user != @user && @current_user.admin? && !@user.admin?
          # 管理者が他の通常ユーザーを編集する場合 → 編集を許可
          # 処理を続行
      elsif @current_user != @user && @current_user.admin? && @user.admin?
          # 管理者が他の管理者を編集しようとした場合 → 編集不可
          redirect_to users_path, alert: 'You cannot edit another admin user.'
      elsif @current_user == @user && !@current_user.admin?
          # 通常ユーザーが自分のデータを編集しようとした場合 → 編集不可
          redirect_to users_path, alert: 'You do not have permission to edit your profile because you are not administrator.'
      else
          # 権限がない場合
          redirect_to root_path, alert: 'You do not have permission to edit this user.'
      end
    end
  

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :password, :admin)
    end
end
