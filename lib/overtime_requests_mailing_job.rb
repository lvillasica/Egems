class OvertimeRequestsMailingJob < Struct.new(:overtime_id, :email_action)

  def perform
    overtime = Overtime.find_by_id(overtime_id)
    action = overtime.action
    employee = overtime.employee
    responders = action.responders
    recipients = Array.new(responders.uniq)
    recipients << employee unless responders.include?(employee)
    success_recipients = []
    failed_recipients = []

    recipients.uniq.compact.each do |recipient|
      begin
        OvertimeMailer.overtime_for_approval(employee, overtime, recipient, email_action).deliver
        success_recipients << recipient.full_name
        msg = "Email notification successfully sent to #{ success_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_overtime_request_mailing_stat", ['success', msg]) rescue p 'Failed to cache mailing status.'
      rescue
        failed_recipients << recipient.full_name
        msg = "Failure on sending email notification to #{ failed_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_overtime_request_mailing_stat", ['error', msg]) rescue p 'Failed to cache mailing status.'
        next
      end
    end
  end

end
