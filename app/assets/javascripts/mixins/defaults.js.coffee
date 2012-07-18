Egems.Mixins.Defaults =
  format_date: (date) ->
    res = I18n.strftime(new Date(date), "%Y-%m-%d")
    res = '--:--' if res == '08:00:00 AM 1970-01-01'
    res.toLowerCase()

  format_long_time: (date) ->
    res = I18n.strftime(new Date(date), '%I:%M:%S %p %Y-%m-%d')
    res = '--:--' if res == '08:00:00 AM 1970-01-01'
    res.toLowerCase()

  format_day_only: (date) ->
    res = I18n.strftime(new Date(date), '%a')

  format_float: (num) ->
    parseFloat(num).toFixed(1)
