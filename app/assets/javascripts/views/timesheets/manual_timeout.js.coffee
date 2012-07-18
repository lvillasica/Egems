class Egems.Views.ManualTimeout extends Backbone.View
  template: JST['timesheets/manual_timeout']

  events: ->
    "click #cancel-manual" : "cancelManual"
    "submit form" : "sendTimesheet"

  render: ->
    $(@el).html(@template(
      invalidTimesheets: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    this

  sendTimesheet: ->
    event.preventDefault()
    timeoutData = $("#manual-timeout-form").serialize()
    $.ajax
      url: '/timeout/manual'
      dataType: 'JSON'
      type: 'POST'
      data: timeoutData
      success: (data) =>
        window.location = ""
      error: (data) =>
        console.log data

  cancelManual: ->
    event.preventDefault()
    home = new Egems.Routers.Timesheets()
    home.index()
