class Egems.Views.TimeEntriesWeekly extends Backbone.View
  template: JST['timesheets/time_entries_weekly']
  id: "weekly-entries"

  render: ->
    $(@el).html(@template(
      timeEntriesPerDay: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    $('#actions-container').remove()
    this
