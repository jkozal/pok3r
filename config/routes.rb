Try::Application.routes.draw do
  resources :users, :user_sessions
  root :to => 'start#index'
  match 'new_account' => 'users#new', :as => :new_account
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
end