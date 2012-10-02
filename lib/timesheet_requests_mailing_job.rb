class TimesheetRequestsMailingJob < Struct.new(:id, :type)

  def perform
    timesheet = Timesheet.find_by_id(id)
    employee = timesheet.employee
    success_recipients = []
    failed_recipients = []

    recipients = Array.new(timesheet.responders)
    recipients << employee

    recipients.uniq.compact.each do |recipient|
      begin
        TimesheetMailer.invalid_timesheet(employee, timesheet, type, recipient).deliver
        success_recipients << recipient.full_name
        msg = "Email notification successfully sent to #{ success_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_timesheet_request_mailing_stat", ['success', msg])
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        failed_recipients << recipient.full_name
        msg = "Failure on sending email notification to #{ failed_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_timesheet_request_mailing_stat", ['error', msg])
        next
      end
    end
  end
end
