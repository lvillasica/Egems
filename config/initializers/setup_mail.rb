ActionMailer::Base.smtp_settings = {
  :address              => "localhost",
  :port                 => 1025,
  :domain               => "localhost:3000",
  :authentication       => "plain",
  :enable_starttls_auto => true
}

ActionMailer::Base.default_url_options[:host] = "localhost:3000"
