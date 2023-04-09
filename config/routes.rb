Rails.application.routes.draw do
  get 'users/index'
  get 'users/create'
  get 'users/edit'
  
  get 'orders/index'
  get 'orders/create'
  get 'orders/capture_order'
  get '/', :to => 'orders#index'
  post :create_order, :to => 'orders#create_order'
  post :capture_order, :to => 'orders#capture_order'
  get '/confirmation', :to => 'orders#payment_confirmation'

  root "orders#index"
end
