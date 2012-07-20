class Egems.Views.TimeEntriesWeekly extends Backbone.View
  template: JST['timesheets/time_entries_weekly']
  id: "time-entries-container"

  render: ->
    $(@el).html(@template(
      timeEntriesPerDay: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    this
