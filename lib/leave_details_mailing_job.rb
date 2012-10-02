class LeaveDetailsMailingJob < Struct.new(:id, :email_action, :owner_id)

  def perform
    leave_detail = LeaveDetail.find_by_id(id)
    responders = leave_detail.responders
    employee = leave_detail.employee
    action_owner = Employee.find_by_id(owner_id)
    job_for = "leave_detail"
    success_recipients = []
    failed_recipients = []
    
    recipients = Array.new(responders.uniq)
    recipients << employee unless responders.include?(employee)

    if leave_detail.needs_hr_action? && leave_detail.is_approved?
      recipients = recipients - employee.hr_personnel
    end

    recipients.uniq.compact.each do |recipient|
      begin
        case email_action
        when 'sent', 'edited', 'canceled'
          LeaveDetailMailer.leave_for_approval(employee, leave_detail, recipient, email_action).deliver
        when 'approved', 'rejected'
          job_for = "leave_request"
          LeaveDetailMailer.leave_action(employee, leave_detail, recipient, email_action, action_owner).deliver
        end
        success_recipients << recipient.full_name
        msg = "Email notification successfully sent to #{ success_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_#{ job_for }_mailing_stat", ['success', msg])
      rescue
        failed_recipients << recipient.full_name
        msg = "Failure on sending email notification to #{ failed_recipients.to_sentence }."
        Rails.cache.write("#{ employee.id }_#{ job_for }_mailing_stat", ['error', msg])
        next
      end
    end
  end

end
