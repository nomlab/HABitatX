require 'net/http'

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :redirect_if_logged_in, only: [:login]

  def login
    if request.post?
      name = params[:name]
      password = params[:password]

      token = request_jws_from_auth_server(name, password)
      p token

      if token.present?
        payload = decode_jws(token)[0]
        p payload
        if payload.present?
          session[:user] = { 'name' => payload['iss'], 'admin' => payload['admin'], 'expires_at' => Time.at(payload['exp']) }
          redirect_to root_path, notice: 'ログインに成功しました。'
        else
          flash.now[:alert] = 'トークンのデコードに失敗しました。'
          render :login
        end
      else
        flash.now[:alert] = '認証サーバーへの接続に失敗しました。'
        render :login
      end
    else
      render :login
    end
  end

  def logout
    reset_session
    redirect_to login_path, notice: 'ログアウトしました。'
  end

  private

  def request_jws_from_auth_server(name, password)
    uri = URI.parse("#{ENV['AUTH_SERVER_PATH']}")
    header = { 'Content-Type': 'application/json' }
    body = { name: name, password: password }.to_json

    response = Net::HTTP.post(uri, body, header)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)['token']
    else
      nil
    end
  end

  def decode_jws(token)
    pub_key = ENV['PUB_KEY']
    JWT.decode(token, pub_key, true, { algorithm: 'HS256' })
  end

  def redirect_if_logged_in
    redirect_to root_path if session[:user].present?
  end
end
