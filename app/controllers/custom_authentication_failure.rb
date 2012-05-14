class CustomAuthenticationFailure < Devise::FailureApp 

  def respond
    if http_auth?
      http_auth
    else
      flash[:alert] = i18n_message unless flash[:notice]
      redirect_to signin_url
    end
  end

  protected 
  
  def redirect_url 
    signin_path
  end
end
