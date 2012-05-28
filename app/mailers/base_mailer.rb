class BaseMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)

  layout 'base_email'
  default :from => "notifications-egems@exist.com"

  def test_mail(to='test@egems.com')
    mail(:to      => to,
         :subject => 'test mail config') do |format|
      format.text {render :text => 'this is a test mail, if you recieve it all configs are fine' }
    end
  end
end
