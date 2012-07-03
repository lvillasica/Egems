module LeaveDetailsHelper

  def show_responders(leave_detail)
    if leave_detail.responder
      leave_detail.responder.full_name
    else
      leave_detail.responders.map(&:full_name).join("<br />").html_safe
    end
  end
  
end
