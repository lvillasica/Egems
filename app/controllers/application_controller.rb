class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery
  
  def after_sign_in_path_for(resource)
    begin
      Timesheet.time_in!(user)
    rescue NoTimeoutError
      @invalid_timesheet = resource.timesheets.latest
    end
    return request.env['omniauth.origin'] || stored_location_for(resource) || timesheets_path
  end
end
