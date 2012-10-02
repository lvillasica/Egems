class Egems.Views.ManualTimein extends Backbone.View
  template: JST['timesheets/manual_timein']

  events: ->
    "click #cancel-manual" : "renderEntries"
    "submit form" : "sendTimesheet"

  initialize: ->
    if this.options.lastTimesheet == null
      @lastTimeout = null
    else
      @lastTimeout = this.options.lastTimesheet.time_out

  render: (options = {}) ->
    $(@el).html(@template(
      invalidTimesheet: @model
      shift: this.options.shift
      lastTimeout: @lastTimeout
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    @flashError(options.error)
    this

  flashError: (msg) ->
    msg ||= this.options.error
    if msg != null
      str = "<div class='alert alert-#{msg[0]}'>" +
            "<button class='close' data-dismiss='alert'>&times;</button>" +
            "#{msg[1]}</div>"
      $(@el).prepend(str)

  sendTimesheet: (event) ->
    event.preventDefault()
    timeinData = $("#manual-timein-form").serialize()
    $.ajax
      url: '/timein/manual'
      dataType: 'JSON'
      type: 'POST'
      data: timeinData
      success: (data) =>
        if data.invalid_timesheet != null
          @render(model: data.invalid_timesheet, error: data.error)
        else
          @check_mailing_job_status(data.mailing_job_id)
          @renderEntries(event)

  renderEntries: (event) ->
    event.preventDefault()
    home = new Egems.Routers.Timesheets()
    home.index()
