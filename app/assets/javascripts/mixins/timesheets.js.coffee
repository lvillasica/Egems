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

  showRemarks: (remarks) ->
    return "" if remarks == null
    _.map(remarks.split(","), (x) ->
      return x.toUpperCase())

  titleRemarks: (remarks) ->
    if remarks != null and @isLeaveFileable(remarks)
      return "File for Leave"
    else
      return ""

  classRemarks: (remarks) ->
    if remarks != null and @isLeaveFileable(remarks)
      return "leavable"
    else
      return ""

  isLeaveFileable: (remarks) ->
    if remarks != null
      remarks = _.map(remarks.split(///[ ]*,[ ]*///), (x) ->
        return x.toUpperCase().trim())
      forLeave = ['AWOL', 'LATE', 'UNDERTIME']
      if _.isEmpty(_.intersection(forLeave, remarks)) == false
        return true
      else
        return false
    else
      return false


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
    advance = new Date(time_in.setHours(time_in.getHours() + 9))
    default_value = new Date(advance.setMinutes(advance.getMinutes() + 1))
    if default_value > current_time
      return current_time
    else
      return default_value

  getDefaultTimeinValue: (timeout, shift) ->
    current = new Date()
    shift = new Date(shift)
    lastOut = new Date(timeout)
    default_value = new Date(current.setHours(current.getHours() - 9))
    if default_value < lastOut
      if lastOut < shift
        return shift
      else
        return new Date(lastOut.setMinutes(lastOut.getMinutes() - 1))
    else
      if default_value < shift
        return shift
      else
        return default_value
