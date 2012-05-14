class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable, :validatable and :omniauthable
  devise :ldap_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body
  before_save :set_user_email
  
  def set_user_email
    self.email = "#{ self.login }@exist.com" if self.email.blank?
  end
end
