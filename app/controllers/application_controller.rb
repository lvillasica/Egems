class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

  def after_sign_in_path_for(resource)
    begin
      Timesheet.time_in!(resource, true)
    rescue Timesheet::NoTimeoutError
      @invalid_timesheets = resource.timesheets.previous.no_timeout
      flash[:alert] = error_message(:no_timeout)
    end if params[:commit].eql?('Time in')
    return request.env['omniauth.origin'] || stored_location_for(resource) || timesheets_path
  end

  def render_404
    #temporary 404 action
    redirect_to timesheets_path
  end

protected
  def error_message(symbol)
    I18n.t "errors.#{symbol}" if symbol.is_a?(Symbol)
  end

end
