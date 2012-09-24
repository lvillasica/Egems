class OvertimeMailer < BaseMailer
  include ApplicationHelper
  include LeaveDetailsHelper

  def overtime_for_approval(requester, overtime, recipient=requester, email_action="sent")
    @requester = requester
    @recipient = recipient
    @date      = format_date(overtime.date_of_overtime)

    @approvers = Array.new(overtime.action.responders - [requester])
    @approvers.compact.uniq!

    if recipient == (requester)
      @receiver_sv = "You have #{ email_action }"
      @receiver_action = 'To view/edit request, please go to:'
      @url = {:action => 'edit', :controller => 'overtimes', :id => overtime.id,
              :only_path => false, :protocol => 'https'}
    elsif @approvers.include?(recipient)
      @receiver_sv = "#{ requester.full_name } has #{ email_action }"
      @receiver_action = 'To take action, please go to:'
      @url = {:action => 'index', :controller => 'overtimes', :only_path => false, :protocol => 'https'}
    else
      @receiver_sv = "#{ requester.full_name } has #{ email_action }"
      @receiver_action = 'To view request, please go to:'
      @url = {:action => 'index', :controller => 'leaves', :only_path => false, :protocol => 'https'}
    end

    mail(:to      => @recipient.email,
         :subject => "[eGEMS]#{ @receiver_sv } an overtime request for approval")
  end
end
