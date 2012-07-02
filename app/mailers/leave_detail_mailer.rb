class LeaveDetailMailer < BaseMailer

  def leave_approval(requester, leave_detail, recipient=requester)
    @requester = requester

    if requester.project_manager == requester.immediate_supervisor
      @approvers = [requester.project_manager]
    else
      @approvers = [requester.project_manager, requester.immediate_supervisor].compact
    end

    @recipient = recipient
    @type = leave_detail.leave_type
    @dated_on = leave_detail.dated_on

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
