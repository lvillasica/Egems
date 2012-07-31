module LeaveDetailsHelper

  def show_responders(leave_detail)
    if leave_detail.responder
      leave_detail.responder.full_name
    else
      leave_detail.responders.map(&:full_name).join("<br />").html_safe
    end
  end

  def get_pending_leaves
  	leaves = @employee.leave_details.select(:leave_unit).pending
  end

  def leave_unit_sum
  	total_units = get_pending_leaves.inject(0) { |sum,leave| sum + leave.leave_unit }
  end

  def leaves_for_hr_approval
    leaves = ["Paternity Leave", "Solo Parent Leave", "Violence Against Women", "Maternity Leave", "Magna Carta"]
  end
  
end
