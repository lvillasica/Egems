Egems.Mixins.Defaults =
  format_date: (date) ->
    res = I18n.strftime(new Date(date), "%Y-%m-%d")
    res = '--:--' if res == '1970-01-01'
    res.toUpperCase()

  format_long_time: (date) ->
    res = I18n.strftime(new Date(date), '%I:%M:%S %p %Y-%m-%d')
    res = '--:--' if res == '08:00:00 AM 1970-01-01'
    res.toUpperCase()

  format_day_only: (date) ->
    res = I18n.strftime(new Date(date), '%a')

  getHour: (time) ->
    I18n.strftime(new Date(time), '%I')

  getMin: (time) ->
    I18n.strftime(new Date(time), '%M')

  getMeridian: (time) ->
    I18n.strftime(new Date(time), '%p')

  format_float: (num) ->
    parseFloat(num).toFixed(1)

  strArrSort: (arr) ->
    _.sortBy(arr, (str) -> str)

  # Returns a method to translate an activerecord attribute
  # through I18n translations.
  # eg. l = Egems.Mixins.Defaults.attrTranslations('leave_detail')
  #     l 'leave_unit'
  attrTranslations: (activerecord_name) ->
    method = (name) ->
      l = I18n.t("activerecord.attributes.#{activerecord_name}.#{name}")
      unless l.match(/missing/) is null
        l = _.map(name.split('_'), (x) -> x[0].toUpperCase() + x.substring(1)).join(' ')
      return l
    return method

  flash_messages: (flash) ->
    flashes = ""
    $('div.alert').remove()
    alert_classes =
      alert: "error"
      error: "error"
      notice: "success"
      success: "success"
      warning: "block"
      info: "info"
    for name, msg of flash
      str = """
            <div class='alert alert-#{alert_classes[name]}'>
               <button class='close' data-dismiss='alert'>&times;</button>
               #{msg}
            </div>
            """
      flashes += str
    flashes

  showFlash: (flash_messages) ->
    $("#main-container").prepend(@flash_messages(flash_messages))
    $('html, body').animate({scrollTop: 0}, 'slow')

  addClassError: (field) ->
    field.closest('.control-group').addClass('error')

  removeClassError: (field) ->
    field.closest('.control-group').removeClass('error')

  listMessageHash: (hash) ->
    msg = ""
    for header, body of hash
      errors = _.map body, (e) ->
        "<li>" + e + "</li>"
      msg += "#{header}<ul>#{errors.join("")}</ul>"
    msg

  loadingIndicator: ->
    str = """
          <div id="loading-indicator" class="modal hide">
            <div class="modal-body" style="padding:0; margin:0">
              <div class="progress progress-striped active" style="padding:0; margin:0">
                <div class="bar" style="width: 100%;">Loading...</div>
              </div>
            </div>
          </div>
          """

  getMinsDiff: (start, end) ->
    start = new Date(start)
    end = new Date(end)
    totalDiff = start.getTime() - end.getTime()
    Math.abs(Math.ceil(totalDiff/1000/60))

  simplePluralize: (num, commonStr) ->
    res = "#{ parseFloat(num).toFixed(1) } #{ commonStr }"
    return if num is 1 then res else res + 's'

  getHoursFromMins: (minutes) ->
    return parseInt(minutes / 60)

  getMinsFromMins: (minutes) ->
    return parseInt(minutes % 60)

  hrsToMins: (hrs, mins) ->
    h = parseInt(hrs) or 0
    m = parseInt(mins) or 0
    return (h * 60) + m

  isNumeric: (event) ->
    key = event.which || event.keyCode;
    if (!event.shiftKey && !event.altKey && !event.ctrlKey &&
       key >= 48 && key <= 57 ||
       key >= 96 && key <= 105 ||
       key == 190 || key == 188 || key == 109 || key == 110 ||
       key == 8 || key == 9 || key == 13 ||
       key == 35 || key == 36 ||
       key == 37 || key == 39 ||
       key == 46 || key == 45)
      return true
    else
      return false
