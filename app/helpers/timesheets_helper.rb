module TimesheetsHelper

  def timesheet_navs(active_time)
    active_time ||= Time.now.beginning_of_day
    nav = %Q{
      <ul class="nav nav-tabs" id="myTab">
      <li class="pull-right"><a href="#week">Week</a></li>
    }
    tabs = []
    current = active_time.localtime.monday
    week_end = (current + 4.days)
    until current > week_end do
      day_full = current.strftime("%A")
      day_abbr = current.strftime("%a")
      active = (active_time.to_date.eql?(current.to_date) ? "active" : nil)
      tabs.prepend(%Q{
        <li class="#{active} pull-right">
          <a href="#{timesheets_nav_path(:time => current)}" data-method="post">#{day_abbr}</a>
        </li>
      })
      current += 1.day
    end
    nav += (tabs.join(" ") << "</ul>")
    nav.html_safe
  end
end
