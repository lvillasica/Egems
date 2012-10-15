module OvertimesHelper

  def overtime_top_nav(current_user, current_uri)
    if current_user.employee.is_supervisor?
      nav = %Q{
              <li class="dropdown #{set_active(current_uri =~ /overtime/ || current_uri.eql?('/overtimes'))}">
                <a id="overtimes-lnk" href="#" data-toggle="dropdown">Overtimes <i class="caret"></i></a>
                <ul class="dropdown-menu">
                  <li>#{link_to "My Overtimes", overtimes_path}</li>
                  <li>#{link_to "Overtime Requests", overtime_requests_path}</li>
                </ul>
              </li>
              }
    else
      nav = %Q{
              <li class="#{set_active(current_uri =~ /overtime/ || current_uri.eql?('/overtimes'))}">
                <a href="#{overtimes_path}">Overtimes</a>
              </li>
              }
    end
    nav.html_safe
  end

end
