class TimesheetMailer < BaseMailer

  def invalid_timesheet(user, timesheet)
    @user = user
    @timesheet = timesheet
    mail(:to       => user.email,
         :subject => 'Invalid Timesheet that needs approval')
  end
end
