class User < ActiveRecord::Base

  require Rails.root.join('lib', 'devise', 'encryptors', 'cipher')

  # -------------------------------------------------------
  # Constants
  # -------------------------------------------------------
  TIMEZONE = 'Asia/Manila'

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable, :validatable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :encryptable

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee

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
  # Class Methods
  # -------------------------------------------------------
  # We are anticipating that timezone display will be from a user preference
  def self.of_localtime(time)
    time.in_time_zone(TIMEZONE)
  end

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

  def den_logs_status
    require 'open-uri'
    url = "#{DEN_URL}/users/check_time_entries?username=#{login}"
    begin
      result = JSON.parse(open(url).read)
      result["complete"]
    rescue => error
      return [false, error]
    end
  end
end
