class TimesheetActionedMailingJob < Struct.new(:id, :type, :action_owner_id, :action)

  def perform
    timesheet = Timesheet.find_by_id(id)
    action_owner = Employee.find_by_id(action_owner_id)
    employee = timesheet.employee

    recipients = Array.new(timesheet.responders)
    recipients << employee

    recipients.uniq.compact.each do |recipient|
      TimesheetMailer.timesheet_action(employee, timesheet, recipient, type, action, action_owner).deliver
    end
  end
end
