module EmployeesHelper

  def hr_module_top_nav(current_user)
    if current_user.employee.is_hr?
      nav = %Q{
              <li class="dropdown">
                <a id="hrmodule-lnk" href="#" data-toggle="dropdown">HR Module <i class="caret"></i></a>
                <ul class="dropdown-menu">
                  <li>#{ link_to "Employee Mapping", employee_mappings_path }</li>
                  <li>#{ link_to "Holidays", holidays_path }</li>
                  <li>#{ link_to "Shift Schedules", shifts_path }</li>
                </ul>
              </li>
              }
      nav.html_safe
    end
  end
end
