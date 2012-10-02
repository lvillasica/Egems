class TimesheetActionedMailingJob < Struct.new(:id, :type, :action_owner_id, :action)

  def perform
    timesheet = Timesheet.find_by_id(id)
    action_owner = Employee.find_by_id(action_owner_id)
    employee = timesheet.employee
    success_recipients = []
    failed_recipients = []

    recipients = Array.new(timesheet.responders)
    recipients << employee

    recipients.uniq.compact.each do |recipient|
      begin
        TimesheetMailer.timesheet_action(employee, timesheet, recipient, type, action, action_owner).deliver
        success_recipients << recipient.full_name
        msg = "Email notification successfully sent to #{ success_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_timesheet_action_mailing_stat", ['success', msg])
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        failed_recipients << recipient.full_name
        msg = "Failure on sending email notification to #{ failed_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_timesheet_action_mailing_stat", ['error', msg])
        next
      end
    end
  end
end
