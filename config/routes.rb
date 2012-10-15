
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
      match '/edit_manual_entry', to: 'timesheets#edit_manual_entry', as: 'timesheets_edit_manual', via: 'put'
      match '/leaves/new', to: 'timesheets#new_leave', as: 'timesheets_new_leave', via: 'get'
      match '/requests', to: 'timesheets#manual_timesheet_requests', as: 'timesheet_requests', via: 'get'
      match '/approve', to: 'timesheets#bulk_approve', as: 'timesheets_approve', via: 'post'
      match '/reject', to: 'timesheets#bulk_reject', as: 'timesheets_reject', via: 'post'
      match '/:time', to: 'timesheets#timesheets_nav', as: 'timesheets_nav', via: 'post'
      match '/:time/week', to: 'timesheets#timesheets_nav_week', as: 'timesheets_nav_week', via: 'post'
    end

    scope '/timesheets/overtimes' do
      match '/requests', to: 'overtimes#requests', as: 'overtime_requests', via: 'get'
      match '/approve', to: 'overtimes#bulk_approve', as: 'overtimes_approve', via: 'post'
      match '/reject', to: 'overtimes#bulk_reject', as: 'overtimes_reject', via: 'post'
    end

    match '/delete/autotimein', :to => 'application#delete_session', :via => :post
    match '/mailing_job_status', :to => 'application#mailing_job_status'

    scope '/leave_details' do
      match '/requests', to: 'leave_details#leave_requests', as: 'leave_requests', via: 'get'
      match '/approve', to: 'leave_details#bulk_approve', as: 'leave_details_approve', via: 'post'
      match '/reject', to: 'leave_details#bulk_reject', as: 'leave_details_reject', via: 'post'
    end


    scope '/hr/holidays' do
      match '', to: 'holidays#index', as: 'holidays', via: 'get'
      match '/new', to: 'holidays#create', as: 'new_holiday', via: 'post'
      match '/edit/:id', to: 'holidays#update', as: 'edit_holiday', via: 'put'
      match '/delete/:id', to: 'holidays#destroy', as: 'delete_holiday', via: 'delete'
    end

    scope '/hr' do
      match '/branches', to: 'branches#index', as: 'branches', via: 'get'
    end

    resources :leave_details, { :except => [:show, :destroy] } do
      member do
        post :cancel
      end
    end

    resources :overtimes, { :except => [:show, :destroy] } do
      member do
        post :cancel
      end
    end

    resources :leaves
    
    resources :employee_mappings, :except => [:new, :edit]

    root :to => 'timesheets#index', :as => 'timesheets', :via => :get
  end
  match '*a', :to => 'application#render_404'
end
