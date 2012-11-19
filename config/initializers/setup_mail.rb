ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address              => "mailtrap.io",
  :port                 => 2525,
  :domain               => "egems.staging.exist.com",
  :authentication       => "plain",
  :enable_starttls_auto => false
}
