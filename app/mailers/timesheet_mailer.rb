class TimesheetMailer < BaseMailer

  def invalid_timesheet(user, timesheet, type)
    @user = user
    @type = type.capitalize.dasherize
    @date = timesheet.date
    @timeout = timesheet.time_out

    #TODO: send mail to approver
    mail(:to      => @user.email,
         :subject => "[eGEMS]You Have Sent #{@type} Request for Approval")
  end
end
