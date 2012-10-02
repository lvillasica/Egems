class Egems.Views.ManualTimeout extends Backbone.View
  template: JST['timesheets/manual_timeout']

  events: ->
    "click #cancel-manual" : "renderEntries"
    "submit form" : "sendTimesheet"

  initialize: ->
    $.ajax
      url: '/delete/autotimein'
      data: 'session=invalid_timein_after_signin'
      type: 'POST'

  render: (options = {}) ->
    $(@el).html(@template(
      invalidTimesheet: @model
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
    timeoutData = $("#manual-timeout-form").serialize()
    $.ajax
      url: '/timeout/manual'
      dataType: 'JSON'
      type: 'POST'
      data: timeoutData
      success: (data) =>
        if data.invalid_timesheet != null
          @render(model: data.invalid_timesheet, error: data.error)
        else
          @check_mailing_job_status("timesheet_request")
          @renderEntries(event)

  renderEntries: (event) ->
    event.preventDefault()
    home = new Egems.Routers.Timesheets()
    home.index()
