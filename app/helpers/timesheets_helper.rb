module TimesheetsHelper

  def overtime_top_nav(current_user, current_uri)
    if current_user.employee.is_supervisor?
      nav = %Q{
              <li class="dropdown #{set_active(current_uri =~ /overtime/ || current_uri.eql?('/overtimes'))}">
                <a class="overtimes-lnk" href="#" data-toggle="dropdown">Overtimes <i class="caret"></i></a>
                <ul class="dropdown-menu">
                  <li>#{link_to "Overtime", overtimes_path}</li>
                  <li>#{link_to "Overtime Requests", overtime_requests_path}</li>
                </ul>
              </li>
              }
    else
      nav = %Q{
              <li class="#{set_active(current_uri =~ /overtime/ || current_uri.eql?('/overtimes'))}">
                <a href="#{overtimes_path}">Overtime</a>
              </li>
              }
    end
    nav.html_safe
  end

  def timesheet_top_nav(current_user, current_uri)
    if current_user.employee.is_supervisor?
      nav = %Q{
              <li class="dropdown #{set_active(current_uri =~ /timesheet/)}">
                <a class="timesheets-lnk" href="#" data-toggle="dropdown">Timesheets <i class="caret"></i></a>
                <ul class="dropdown-menu">
                  <li>#{link_to "My Timecard", timesheets_path}</li>
                  <li>#{link_to "Timesheet Requests", timesheet_requests_path}</li>
                </ul>
              </li>
              }
    else
      nav = %Q{
              <li class="#{set_active(current_uri =~ /timesheet/ || current_uri.eql?('/'))}">
                <a href="#{timesheets_path}">Timesheets</a>
              </li>
              }
    end
    nav.html_safe
  end

  def timesheet_navs(active_time)
    active_time ||= Time.now.beginning_of_day
    if active_time.is_a?(Array)
      active_range = "active"
      active_time = active_time.first
    end

    tabs = []
    current = active_time.localtime.monday
    week_end = current.sunday
    nav = %Q{
      <ul class="nav nav-tabs" id="myTab">
      <li class="input-append">
        <input type="text" id="week-picker" class="span2 disabled" value="#{ get_week(active_time).join(' to ') }" />
      </li>
      <li class="#{active_range} pull-right">
        <a id="week_tab" href="#{timesheets_nav_week_path(:time => current)}" data-method="post">Week</a>
      </li>
    }
    until current > week_end do
      day_full = current.strftime("%A")
      day_abbr = current.strftime("%a")
      active = (active_time.to_date.eql?(current.to_date) && !active_range ? "active" : nil)
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

  def get_week(active_time)
    active_time ||= Time.now.beginning_of_day
    if active_time.is_a?(Range)
      active_time = active_time.first
    end
    current = active_time.localtime.monday
    week_end = current.sunday
    [format_date(current), format_date(week_end)]
  end

  def format_in_hours(minutes)
    str = []
    hrs = (minutes / 1.minute).to_i
    mins = (minutes % 1.minute).to_i

    str << "#{hrs}h" if hrs > 0
    str << "#{mins}m" if mins > 0
    str.empty? ? "0" : str.join(" ")
  end

  def sum_minutes(timesheets)
     timesheets.sum(&:duration)
  end

  def sum_late(timesheets)
    timesheets.sum(&:minutes_late)
  end

  def sum_undertime(timesheets)
    timesheets.sum(&:minutes_undertime)
  end

  def sum_excess(timesheets)
    timesheets.sum(&:minutes_excess)
  end

  def get_last_timeout
    last_timeout = @employee.timesheets.asc.last.time_out
  end

  def get_last_timein
    last_timein = @employee.timesheets.asc.last.time_in
  end

#----------------------------------------------------------------
# Autopopulate manual timein entry
#----------------------------------------------------------------
  def get_new_shift_am_date
    date_today            = Time.now.strftime("%F").split("-")
    day_of_week           = Time.now.wday
    am_time_allowance     = @employee.shift_schedule.details[day_of_week].am_time_allowance
    am_time_start         = @employee.shift_schedule.details[day_of_week].am_time_start
    shift_time_start      = (am_time_start - am_time_allowance.minutes).strftime("%I-%M-%S").split("-")
    shift_am_new_datetime = Time.parse((date_today + shift_time_start).join)
  end

  def get_default_timein_value
    default_value = Time.now.advance(hours: - 9, minutes: -1)
    am_shift      = get_new_shift_am_date
    last_timeout  = get_last_timeout.to_datetime.new_offset Rational(8,24) #set it to +8:00

      if default_value < last_timeout
        last_timeout < am_shift ? default_value = am_shift : default_value = last_timeout + 1.minutes
      else
        default_value < am_shift ? default_value = am_shift : default_value
      end
  end



#----------------------------------------------------------------
# Autopopulate manual timeout entry
#----------------------------------------------------------------
  def get_default_timeout_value
    current_time  = Time.now
    last_timein   = get_last_timein.to_datetime.new_offset Rational(8,24) #set it to +8:00
    default_value = last_timein.advance(hours: 9, minutes: 1)

    default_value > current_time ? default_value = current_time : default_value
  end


  def get_hours(default_time)
    default_time.strftime("%I")
  end

  def get_minutes(default_time)
    default_time.strftime("%M")
  end

  def get_meridian(default_time)
    default_time.strftime("%p")
  end

end
