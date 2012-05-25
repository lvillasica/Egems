class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable, :validatable and :omniauthable
  devise :ldap_authenticatable, :registerable,
              :recoverable, :rememberable, :trackable

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  has_many :timesheets, :table_name => 'employee_timesheets',
                                          :foreign_key => 'employee_id',
                                          :primary_key => 'employee_id'
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_uniqueness_of :login, :email

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_user_email

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me
  attr_accessible :employee_id

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------

  def with_time_entries_today?
    today = Date.today.beginning_of_day
    entries_today = timesheets.where(:date => today)
    return entries_today.empty?
  end

  def set_user_email
    self.email = ("%s@%s" % [self.login, DEFAULT_EMAIL_DOMAIN])if self.email.blank?
  end
end
