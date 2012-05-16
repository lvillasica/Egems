Egems::Application.routes.draw do
  # we need to skip routes not needed
  devise_for :users, :skip => [:registration, :password]
  devise_scope :user do
    root   :to => 'devise/sessions#new', :as => 'signin', :via => :get
    get    '/signin'  => 'devise/sessions#new'
    post   '/signin'  => 'devise/sessions#create'
    delete '/signout' => 'devise/sessions#destroy'
  end

  resources :timesheets, :only => [:index, :timein, :timeout]
  match '/timein', to: 'timesheets#timein'
  match '/timeout', to: 'timesheets#timeout'
  root :to => 'timesheets#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
