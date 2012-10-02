class TimesheetRequestsMailingJob < Struct.new(:id, :type)

  def perform
    timesheet = Timesheet.find_by_id(id)
    employee = timesheet.employee

    recipients = Array.new(timesheet.responders)
    recipients << employee

    recipients.uniq.compact.each do |recipient|
      TimesheetMailer.invalid_timesheet(employee, timesheet, type, recipient).deliver
    end
  end
end
