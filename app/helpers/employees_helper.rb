module EmployeesHelper

  def hr_module_top_nav(current_user)
    if current_user.employee.is_hr?
      nav = %Q{
              <li class="dropdown">
                <a id="hrmodule-lnk" href="#" data-toggle="dropdown">HR Module <i class="caret"></i></a>
                <ul class="dropdown-menu">
                  <li>#{link_to "Holidays", holidays_path}</li>
                  <li><a>Link2</a></li>
                </ul>
              </li>
              }
      nav.html_safe
    end
  end
end
