class Egems.Views.TimesheetsIndex extends Backbone.View
  
  template: JST['timesheets/index']
  
  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets)
    @collection.on('reset', @render, this)
  
  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
    this
  
  appendTimeEntry: (timeEntry) =>
    view = new Egems.Views.TimeEntry(model: timeEntry)
    @$('#time-entries tbody').append(view.render().el)
