class ApplicationController < ActionController::Base
  before_action :authorize_request, except: :index
  before_action :admin_only, only: [:new, :edit, :destroy]

  private

  def authorize_request
    token = session[:token]

    if token
      begin
        decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
        @current_user = User.find(decoded[0]['id'])
        p @current_user
      rescue JWT::ExpiredSignature
        # トークンの期限が切れている場合はセッションからトークンを削除
        session.delete(:token)
        redirect_to login_path, alert: 'Session expired. Please log in again.'
      rescue JWT::DecodeError
        # トークンのデコードエラー（無効なトークンなど）
        session.delete(:token)
        redirect_to login_path, alert: 'Invalid token. Please log in again.'
      end
    else
      redirect_to login_path, alert: 'Login is required'
    end
  end

  def admin_only
    if @current_user && !@current_user.admin
      redirect_to login_path, alert: 'Access restricted to admins only'
    end
  end
end
