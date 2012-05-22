class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

  def after_sign_in_path_for(resource)
    begin
      Timesheet.time_in!(resource, true)
    rescue Timesheet::NoTimeoutError
      @invalid_timesheets = resource.timesheets.invalid
    end if params[:commit].eql?('Time in')
    return request.env['omniauth.origin'] || stored_location_for(resource) || timesheets_path
  end

 def render_404
    #temporary 404 action
    redirect_to root_path
  end
end
