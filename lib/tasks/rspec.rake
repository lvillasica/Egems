begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:rspec => 'db:test:prepare') do |t|
    t.pattern = "./spec/**"
  end
rescue LoadError
end

