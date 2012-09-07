
Egems::Application.routes.draw do

  # we need to skip routes not needed
  devise_for :users, :skip => [:registration, :password]
  unauthenticated :user do
    devise_scope :user do
      root   :to => 'devise/sessions#new', :as => 'signin', :via => :get
      get    '/signin'  => 'devise/sessions#new'
      post   '/signin'  => 'devise/sessions#create'
    end
  end

  authenticated :user do
    devise_scope :user do
      delete '/signout' => 'devise/sessions#destroy'
    end
    match '/timein', to: 'timesheets#timein', via: 'post'
    match '/timeout', to: 'timesheets#timeout', via: 'post'
    match '/timeout/manual/', to: 'timesheets#manual_timeout', as: 'manual_timeout', via: 'post'
    match '/timein/manual/', to: 'timesheets#manual_timein', as:  'manual_timein', via: 'post'

    scope '/timesheets' do
      match '/manual_time_entry', to: 'timesheets#manual_time_entry', as: 'timesheets_manual_entry', via: 'post'
      match '/:time', to: 'timesheets#timesheets_nav', as: 'timesheets_nav', via: 'post'
      match '/:time/week', to: 'timesheets#timesheets_nav_week', as: 'timesheets_nav_week', via: 'post'
      match '/leaves/new', to: 'timesheets#new_leave', as: 'timesheets_new_leave', via: 'get'
      match '/overtimes/new', to: 'timesheets#new_overtime', as: 'timesheets_new_overtime', via: 'get'
      match '/requests', to: 'timesheets#manual_timesheet_requests', as: 'timesheet_requests', via: 'get'
    end

    match '/delete/autotimein', :to => 'application#delete_session', :via => :post

    scope '/leave_details' do
      match '/requests', to: 'leave_details#leave_requests', as: 'leave_requests', via: 'get'
      match '/approve', to: 'leave_details#bulk_approve', via: 'post'
      match '/reject', to: 'leave_details#bulk_reject', via: 'post'
    end

    resources :leave_details, { :except => [:show, :destroy] } do
      member do
        post :cancel
      end
    end

    resources :overtimes
    resources :leaves

    root :to => 'timesheets#index', :as => 'timesheets', :via => :get
  end
  match '*a', :to => 'application#render_404'
end
