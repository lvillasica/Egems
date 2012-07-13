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

  getActiveDay: (date) ->
    mon: @getDay(date.clone().monday())
    tue: @getDay(date.clone().tuesday())
    wed: @getDay(date.clone().wednesday())
    thu: @getDay(date.clone().thursday())
    fri: @getDay(date.clone().friday())
    sat: @getDay(date.clone().saturday())
    sun: @getDay(date.clone().saturday().addDays(1))
  
  getDay: (date) ->
    if date > Date.today().clone().saturday().addDays(1)
      return date.clone().addDays(-7)
    else
      return date.clone()
