class LeaveDetailMailer < BaseMailer
  include LeaveDetailsHelper

  def leave_approval(requester, leave_detail, recipient=requester)
    @requester = requester
    @recipient = recipient
    @type      = leave_detail.leave_type
    @dated_on  = leave_detail.dated_on


    if requester.project_manager == requester.immediate_supervisor
      @approvers = [requester.project_manager]
    elsif leaves_for_hr_approval.include?(@type)
      @approvers = requester.hr_personnel
    else
      @approvers = [requester.project_manager, requester.immediate_supervisor].compact
    end 

    if recipient == (requester)
      @receiver_sv = 'You have'
      @receiver_action = 'To view/edit request, please go to:'
    elsif leaves_for_hr_approval.include?(@type)
      requester.hr_personnel.include?(@recipient) ?  @receiver_action = 'To take action, please go to:' : @receiver_action = 'To view request, please go to:' 
      @receiver_sv = "#{requester.full_name} has"
    else
      @receiver_sv = "#{requester.full_name} has"
      @receiver_action = 'To take action, please go to:'
    end

    mail(:to      => @recipient.email,
         :subject => "[eGems]#{@receiver_sv} sent a #{@type} request for approval")
  end
end
