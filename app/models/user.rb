class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable, :validatable and :omniauthable
  devise :ldap_authenticatable, :registerable,
              :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  has_many :timesheets, :table_name => 'employee_timesheets',
                                          :foreign_key => 'employee_id',
                                          :primary_key => 'employee_id'

  before_save :set_user_email
  
  def time_in_automatable?
    today = Date.today.beginning_of_day
    entries_today = timesheets.where(:date => today)
    latest_entry = entries_today.last
    return entries_today.empty? || (latest_entry && !latest_entry.time_out.blank?)
  end

  def set_user_email
    self.email = "#{ self.login }@exist.com" if self.email.blank?
  end
end
