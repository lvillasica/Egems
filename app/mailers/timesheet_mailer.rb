class TimesheetMailer < BaseMailer

  def invalid_timesheet(requester, timesheet, type, recipient=requester)
    @requester = requester
    @approvers = [requester.project_manager, requester.immediate_supervisor].compact
    @recipient = recipient
    @type = type.capitalize.dasherize
    @date = timesheet.date
    @time = timesheet[type]

    if recipient == (requester)
      @receiver_sv = 'You have'
      @receiver_action = 'To view/edit request, please go to:'
    else
      @receiver_sv = "#{requester.full_name} has"
      @receiver_action = 'To take action, please go to:'
    end

    mail(:to      => @recipient.email,
         :subject => "[eGems]#{@receiver_sv} sent a #{@type} request for approval")
  end
end
