class Egems.Views.TimesheetsIndex extends Backbone.View
  
  template: JST['timesheets/index']
  
  initialize: ->
    @collection.on('reset', @render, this)
  
  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
    this
  
  appendTimeEntry: (timeEntry) =>
    view = new Egems.Views.TimeEntry(
      model: timeEntry
      collection: @collection
    )
    @$('#time-entries tbody').append(view.render().el)
