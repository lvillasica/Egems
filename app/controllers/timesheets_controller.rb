class TimesheetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  def index
    redirect_to signin_url unless user_signed_in?
  end
end
