class AuthController < ApplicationController
  skip_before_action :admin_only
  skip_before_action :authorize_request
  def login_form
  end
  def login
    user = User.find_by(name: params[:name])

    if user && user.authenticate(params[:password])
      payload = {
        id: user.id,
        name: user.name,
        admin: user.admin,
        exp: 30.minutes.from_now.to_i
      }
      token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')

      # セッションにトークンを保存
      session[:token] = token
      
      # ログイン成功後にroot_pathへリダイレクト
      redirect_to root_path
    else
      flash.now[:alert] = 'Invalid name or password'
      render :login_form
    end
  end

  def logout
    session.delete(:token)
    redirect_to login_path
  end
end
