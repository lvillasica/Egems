class LeaveDetailMailer < BaseMailer

  def leave_approval(requester, leave_detail, recipient=requester)
    @requester = requester
    @approvers = [requester.project_manager, requester.immediate_supervisor].compact
    @recipient = recipient
    @type = leave_detail.leave_type
    start_date = leave_detail.leave_date.localtime.to_date
    end_date = (start_date + leave_detail.leave_unit.ceil.days)
    range = (start_date ... end_date).to_a
    l_start_date = I18n.l(range.first, :format => :long_date_with_day)
    l_end_date = I18n.l(range.last, :format => :long_date_with_day) unless range.count == 1
    date = [l_start_date, l_end_date].compact.join(' to ')
    am_pm = {1 => "AM", 2 => "PM"}
    period = am_pm[leave_detail.period]
    @dated_at = [date, period].compact.join(" ")

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
