Rails.application.routes.draw do
  resources :templates
  resources :items
  resources :items_groups

  # get '/items_groups', to: 'items_groups#index', as: :items_groups
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # ログインページを表示するためのルート
  get '/login', to: 'auth#login'

  # ログインフォームからPOSTされたデータを処理するためのルート
  post '/login', to: 'auth#login'

  # ログアウトを行うためのルート
  delete '/logout', to: 'auth#logout', as: 'logout'

  root 'index#index', as: 'root'
  
  
  
  
  # get "/login", to: 'auth#login', as: 'login'
  # post "/login", to: 'auth#create'
  # post "/receive_token", to: 'auth#receive_token'

  # Defines the root path route ("/")
  # root "posts#index"
end
