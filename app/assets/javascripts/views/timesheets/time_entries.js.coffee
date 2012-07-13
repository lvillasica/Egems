class Egems.Views.TimeEntries extends Backbone.View
  
  template: JST['timesheets/time_entries']
  
  initialize: ->
    @collection.on('reset', @render, this)
  
  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
    this
  
  appendTimeEntry: (timeEntry) =>
    view = new Egems.Views.TimeEntry(model: timeEntry)
    @$('#time-entries tbody').append(view.render().el)
