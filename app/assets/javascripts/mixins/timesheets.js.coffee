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

  weekPickerVal: (date) ->
    day = @getDayOfWeek(date)
    mon = Egems.Mixins.Defaults.format_date(day.mon)
    sun = Egems.Mixins.Defaults.format_date(day.sun)
    return [mon, sun].join(' to ')
