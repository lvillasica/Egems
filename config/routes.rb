
Egems::Application.routes.draw do

  # we need to skip routes not needed
  devise_for :users, :skip => [:registration, :password]
  devise_scope :user do
    root   :to => 'devise/sessions#new', :as => 'signin', :via => :get
    get    '/signin'  => 'devise/sessions#new'
    post   '/signin'  => 'devise/sessions#create'
  end

  authenticated :user do
    devise_scope :user do
      delete '/signout' => 'devise/sessions#destroy'
    end
    resources :timesheets, :only => [:index]
    match '/timein', to: 'timesheets#timein', via: 'post'
    match '/timeout', to: 'timesheets#timeout', via: 'post'
    match '/timeout/manual/', to: 'timesheets#manual_timeout', as: 'manual_timeout', via: 'post'
    match '/timein/manual/', to: 'timesheets#manual_timein', as:  'manual_timein', via: 'post'
    root :to => 'timesheets#index'
  end

  match '*a', :to => 'application#render_404'
end
