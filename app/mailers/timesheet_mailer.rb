class TimesheetMailer < BaseMailer

  def invalid_timesheet(user, timesheet)
    @user = user
    @timesheet = timesheet
    mail(:to       => user.email,
         :subsject => 'Invalid Timesheet that needs approval')
  end
end
