class LeaveDetailMailer < BaseMailer
  include ApplicationHelper
  include LeaveDetailsHelper

  def leave_for_approval(requester, leave_detail, recipient=requester, email_action="sent")
    @requester = requester
    @recipient = recipient
    @type      = leave_detail.leave_type
    @dated_on  = leave_detail.dated_on

    if Leave::SPECIAL_TYPES.include?(@type)
      if requester.hr_personnel.include?(requester)
        @approvers = [requester.immediate_supervisor].compact
      else
        @approvers = requester.hr_personnel.compact
      end
    else
      if requester.project_manager == requester.immediate_supervisor
        @approvers = [requester.project_manager]
      else
        @approvers = [requester.project_manager, requester.immediate_supervisor].compact
      end
    end

    if recipient == (requester)
      @receiver_sv = "You have #{email_action}"
      @receiver_action = 'To view/edit request, please go to:'
      @url = {:action => 'edit', :controller => 'leave_details', :id => leave_detail.id,
              :only_path => false, :protocol => 'https'}
    elsif @approvers.include?(recipient)
      @receiver_sv = "#{requester.full_name} has #{email_action}"
      @receiver_action = 'To take action, please go to:'
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    else
      @receiver_sv = "#{requester.full_name} has #{email_action}"
      @receiver_action = 'To view request, please go to:'
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    end

    mail(:to      => @recipient.email,
         :subject => "[eGems]#{@receiver_sv} #{email_action} #{indifinitize @type} request for approval")
  end

  def leave_action(requester, leave_detail, recipient=requester, action, action_owner)
    @recipient = recipient
    @requester = requester
    @type = leave_detail.leave_type
    @dated_on = leave_detail.dated_on
    @action = action

    @receiver_sv = (recipient == action_owner) ? "You have #{action} " : "#{action_owner.full_name} has #{action} "
    if recipient == requester
      @receiver_sv << "your"
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    else
      @receiver_sv << "#{requester.full_name}'s"
      @url = {:action => 'leave_requests', :controller => 'leave_details', :only_path => false, :protocol => 'https'}
    end

    mail(:to      => @recipient.email,
         :subject => "[eGEMS] #{@requester.full_name} #{@type} request has been #{action}")
  end
end
