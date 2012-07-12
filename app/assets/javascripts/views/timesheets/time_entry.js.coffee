class Egems.Views.TimeEntry extends Backbone.View
  template: JST['timesheets/time_entry']
  tagName: 'tr'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      timeEntry: @model
      collection: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
      size: @collection.length
    ))
    this
