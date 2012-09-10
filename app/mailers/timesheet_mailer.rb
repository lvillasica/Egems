class TimesheetMailer < BaseMailer

  def invalid_timesheet(requester, timesheet, type, recipient=requester)
    @requester = requester

    if requester.project_manager == requester.immediate_supervisor
      @approvers = [requester.project_manager]
    else
      @approvers = [requester.project_manager, requester.immediate_supervisor].compact
    end

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
         :subject => "[eGEMS]#{@receiver_sv} sent a #{@type} request for approval")
  end

  def timesheet_action(requester, timesheet, recipient=requester, type, action, action_owner)
    @receiver_sv = (recipient == action_owner) ? "You have #{action} " : "#{action_owner.full_name} has #{action} "
    @receiver_sv << (recipient == requester ? "your" : "#{requester.full_name}'s")
    @recipient = recipient
    @requester = requester
    @type = type.capitalize.dasherize
    @time = timesheet[type]
    @approvers = timesheet.responders.compact.uniq

    mail(:to      => @recipient.email,
         :subject => "[eGEMS] #{@requester.full_name} #{@type} request has been #{action}")
  end
end
