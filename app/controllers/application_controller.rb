class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery
  
  def after_sign_in_path_for(resource)
    path = (params[:commit].eql?("Time in") ? timein_path : timesheets_path)
    return request.env['omniauth.origin'] || stored_location_for(resource) || path
  end
end
