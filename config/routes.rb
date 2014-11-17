Rails.application.routes.draw do
  devise_for :users
  resources :beers
  root 'beers#index'
end
