class BaseMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)

  layout 'base_email'
  default :from => "notifications-egems@exist.com"
end
