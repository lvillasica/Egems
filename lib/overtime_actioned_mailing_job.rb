class OvertimeActionedMailingJob < Struct.new(:id, :action, :action_owner_id)

  def perform
    action_owner = Employee.find_by_id(action_owner_id)
    overtime_action = OvertimeAction.find_by_id(id)
    overtime = overtime_action.overtime
    requester = overtime.employee
    responders = overtime_action.responders.uniq

    success_recipients = []
    failed_recipients = []

    recipients = Array.new(responders)
    recipients << requester unless responders.include?(requester)

    recipients.uniq.compact.each do |recipient|
      begin
        OvertimeMailer.overtime_action(requester, overtime, recipient, action, action_owner).deliver
        success_recipients << recipient.full_name
        msg = "Email notification successfully sent to #{ success_recipients.to_sentence }."
        Rails.cache.write("#{ action_owner_id }_overtime_action_mailing_stat", ['success', msg]) rescue p 'Failed to cache mailing status.'
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        failed_recipients << recipient.full_name
        msg = "Failure on sending email notification to #{ failed_recipients.to_sentence }."
        Rails.cache.write("#{ action_owner_id }_overtime_action_mailing_stat", ['error', msg]) rescue p 'Failed to cache mailing status.'
        next
      end
    end
  end
end
