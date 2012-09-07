class Egems.Views.TimesheetDetails extends Backbone.View

  template: JST['timesheets/details']

  render: ->
    $(@el).html(@template(
      timesheet: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    this
