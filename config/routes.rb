Rails.application.routes.draw do
  root 'home#index'
  get 'home/load'
  post 'home/ask'
end
