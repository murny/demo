require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app
  resources :messages, except: [:new, :show]
  root "messages#index"

  get 'healthcheck', to: 'healthcheck#index'
end
