module TimesheetsHelper

  def timesheet_navs(active_date)
    active_date ||= Date.today
    nav = %Q{
      <ul class="nav nav-tabs" id="myTab">
      <li class="pull-right"><a href="#week">Week</a></li>
    }
    week_start = active_date.monday
    week_end = (week_start + 4.days)
    (week_start .. week_end).reverse_each do |date|
      day_full = date.strftime("%A")
      day_abbr = date.strftime("%a")
      active = (active_date.eql?(date) ? "active" : "")
      nav += %Q{
        <li class="#{active} pull-right">
          <a href="##{day_full.downcase}">#{day_abbr}</a>
        </li>
      }
    end
    nav += "</ul>"
    nav.html_safe
  end
end
