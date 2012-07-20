Egems.Mixins.Timesheets =
  format_in_hours: (minutes) ->
    str = []
    hrs = parseInt(minutes / 60)
    mins = parseInt(minutes % 60)
    str.push "#{hrs}h" if hrs > 0
    str.push "#{mins}m" if mins > 0
    if str.length >= 1
      return str.join(" ")
    else
      return "0"

  getDayOfWeek: (date) ->
    dateOnly = date.clone().clearTime()
    mon: @getDay(dateOnly, dateOnly.clone().monday())
    tue: @getDay(dateOnly, dateOnly.clone().tuesday())
    wed: @getDay(dateOnly, dateOnly.clone().wednesday())
    thu: @getDay(dateOnly, dateOnly.clone().thursday())
    fri: @getDay(dateOnly, dateOnly.clone().friday())
    sat: @getDay(dateOnly, dateOnly.clone().saturday())
    sun: @getDay(dateOnly, dateOnly.clone().sunday())

  getDay: (current, date) ->
    if date > current.clone().sunday() || date is Date.today()
      return date.clone().addDays(-7)
    else
      return date.clone()

  getHour: (time) ->
    I18n.strftime(new Date(time), "%I").toLowerCase()

  getMinute: (time) ->
    I18n.strftime(new Date(time), "%M").toLowerCase()

  getMeridian: (time) ->
    I18n.strftime(new Date(time), "%p").toLowerCase()

  weekPickerVal: (date) ->
    day = @getDayOfWeek(date)
    mon = Egems.Mixins.Defaults.format_date(day.mon)
    sun = Egems.Mixins.Defaults.format_date(day.sun)
    return [mon, sun].join(' to ')

  getDefaultTimeoutValue: (timein) ->
    current_time = new Date()
    time_in = new Date(timein)
    default_value = new Date(time_in.setHours(time_in.getHours() + 9))
    if default_value > current_time
      return current_time
    else
      return default_value

  getDefaultTimeinValue: (timeout) ->
    current_time = new Date()
    time_out = new Date(timeout)
    default_value = new Date(time_out.setHours(time_out.getHours() - 9))
    return default_value
