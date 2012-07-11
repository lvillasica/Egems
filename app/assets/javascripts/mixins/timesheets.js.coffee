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
