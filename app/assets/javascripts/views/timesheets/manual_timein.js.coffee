class Egems.Views.ManualTimein extends Backbone.View
  template: JST['timesheets/manual_timein']

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
    alert "send timesheet"

  cancelManual: ->
    event.preventDefault()
    home = new Egems.Routers.Timesheets()
    home.index()
