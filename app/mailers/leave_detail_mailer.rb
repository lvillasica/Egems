class LeaveDetailMailer < BaseMailer
  include ApplicationHelper
  include LeaveDetailsHelper

  def leave_for_approval(requester, leave_detail, recipient=requester, email_action="sent")
    @requester = requester
    @recipient = recipient
    @type      = leave_detail.leave_type
    @dated_on  = leave_detail.dated_on

    @approvers = Array.new(leave_detail.responders - [requester])
    if leave_detail.needs_hr_approval? && leave_detail.is_hr_approved?
      @approvers = @approvers - [requester.immediate_supervisor, requester.project_manager]
    end
    @approvers.compact.uniq!

    if recipient == (requester)
      @receiver_sv = "You have #{email_action}"
      @receiver_action = 'To view/edit request, please go to:'
      @url = {:action => 'edit', :controller => 'leave_details', :id => leave_detail.id,
              :only_path => false, :protocol => 'https'}
    elsif @approvers.include?(recipient)
      @receiver_sv = "#{requester.full_name} has #{email_action}"
      @receiver_action = 'To take action, please go to:'
      @url = {:action => 'leave_requests', :controller => 'leave_details', :only_path => false, :protocol => 'https'}
    else
      @receiver_sv = "#{requester.full_name} has #{email_action}"
      @receiver_action = 'To view request, please go to:'
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    end

    mail(:to      => @recipient.email,
         :subject => "[eGEMS]#{@receiver_sv} #{indifinitize @type} request for approval")
  end

  def leave_action(requester, leave_detail, recipient=requester, action, action_owner)
    @recipient = recipient
    @requester = requester
    @type = leave_detail.leave_type
    @dated_on = leave_detail.dated_on
    @action = action

    if action_owner.is_hr? && leave_detail.is_hr_approved?
      subject = "[eGEMS] #{@requester.full_name} #{@type} request has been #{action} by HR"
      managers = [requester.immediate_supervisor, requester.project_manager].compact.uniq
      @approvers = managers
    else
      subject = "[eGEMS] #{@requester.full_name} #{@type} request has been #{action}"
    end

    @receiver_sv = (recipient == action_owner) ? "You have #{action} " : "#{action_owner.full_name} has #{action} "

    if recipient == requester
      @receiver_sv << "your"
      @receiver_action = "To view request, please go to:"
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    else
      @receiver_sv << "#{requester.full_name}'s"
      if leave_detail.is_hr_approved? && managers.include?(recipient)
        @receiver_action = "To take action, please go to:"
      else
        @receiver_action = "To view request, go to:"
      end
      @url = {:action => 'leave_requests', :controller => 'leave_details', :only_path => false, :protocol => 'https'}
    end

    mail(:to      => @recipient.email,
         :subject => subject)
  end
end
