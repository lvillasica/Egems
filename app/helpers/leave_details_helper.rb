module LeaveDetailsHelper

  def leave_details_top_nav(current_user, current_uri)
    if current_user.employee.can_action_leaves?
      li_requests = "<li>#{link_to "Leave Requests", leave_requests_path}</li>"
    end

    nav = %Q{
            <li class="dropdown #{set_active(current_uri =~ /leave/)}">
              <a id="leaves-lnk" href="#" data-toggle="dropdown">Leaves <i class="caret"></i></a>
              <ul class="dropdown-menu">
                <li>#{link_to "My Leaves", leaves_path}</li>
                #{li_requests}
                <li class="divider"></li>
                <li>#{link_to "Apply for Leave", new_leave_detail_path}</li>
              </ul>
            </li>
            }
    nav.html_safe
  end

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
    Leave::SPECIAL_TYPES
  end

end
