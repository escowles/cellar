Rails.application.routes.draw do
  devise_for :users
  get "beers/checkout" => "beers#checkout", :as => :checkout
  resources :beers
  root 'beers#index'
end
