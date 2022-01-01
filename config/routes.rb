require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/admin/sidekiq" # mount Sidekiq::Web in your Rails app
  resources :messages
  root "messages#index"

  get 'healthcheck', to: 'healthcheck#index'
end
