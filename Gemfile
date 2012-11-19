source 'https://rubygems.org'

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

group :production do
  gem 'pg'
  # Use unicorn as the app server
  gem 'unicorn'
end


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
  gem 'twitter-bootstrap-rails'
  # gem 'backbone-rails'
end

gem 'jquery-rails'
gem 'devise'
gem "devise_ldap_authenticatable", :git => "git://github.com/cschiewek/devise_ldap_authenticatable.git"
gem 'backbone-on-rails'
gem 'i18n-js'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'mailcatcher'
gem 'mailtrap'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
group :test do
  gem 'rspec-rails', '>= 2.5.0'
  gem 'shoulda'
  gem 'timecop'
  gem 'turnip'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'launchy'
  gem 'pry'
  gem 'sqlite3'
end

group :development do
  gem 'sqlite3'
  gem 'pry'
  # Deploy with Capistrano
  gem 'capistrano'
end
