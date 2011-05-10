Try::Application.routes.draw do
  resources :events

  resources :coupons

  resources :users, :user_sessions
  root :to => 'start#index'
  match 'new_account' => 'users#new', :as => :new_account
  match 'user/login' => 'user_sessions#new', :as => :login
  match 'user/logout' => 'user_sessions#destroy', :as => :logout
  match 'sedna' => 'sedna#index', :as => :sedna
  match 'start/lista' => 'start#lista'
  match 'start/enter' => 'start#enter'
  match 'start/getkupon' => 'start#getkupon'
  match 'start/xmlgenerate' => 'start#xmlgenerate'
end