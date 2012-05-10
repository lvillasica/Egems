Egems::Application.routes.draw do
  # we need to skip routes not needed
  devise_for :users
  devise_scope :user do
    get    '/signin'  => 'devise/sessions#new'
    post   '/signin'  => 'devise/sessions#create'
    delete '/signout' => 'devise/sessions#destroy'
  end

  resources :timesheets

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
