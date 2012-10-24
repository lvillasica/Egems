class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

  def after_sign_in_path_for(resource)
    employee = resource.employee
    begin
      Timesheet.time_in!(employee)
    rescue Timesheet::NoTimeoutError
      session[:invalid_timein_after_signin] = true
    end if params[:commit].eql?('Time in')
    return request.env['omniauth.origin'] || stored_location_for(resource) || timesheets_path
  end

  def render_404
    #temporary 404 action
    redirect_to timesheets_path
  end

  def delete_session
    session.delete(params[:session].to_sym)
    render :nothing => true
  end

  def mailing_job_status
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    
    job_for = params[:job_for]
    employee = current_user.employee
    cached_status = Rails.cache.fetch("#{ employee.id }_#{ job_for }_mailing_stat")
    if cached_status.is_a?(Array)
      @msg = "data: #{ cached_status.to_json }\n\n"
    else
      @msg = "data: null\n\n"
    end
    Rails.cache.delete("#{ employee.id }_#{ job_for }_mailing_stat")
    
    render :text => @msg
  end

protected
  def flash_message(type,symbol_or_string)
    flash[type] = case symbol_or_string
                  when Symbol then t("views.flash.#{type.to_s}.#{symbol_or_string}")
                  when String then symbol_or_string
                  when Array then symbol_or_string.join("</br>")
                  else nil
                  end
  end

  def js_params
    @js_params ||= {}
    @data = @js_params
  end

  def js_params_json(options = {})
    js_params.to_json(options)
  end

end
