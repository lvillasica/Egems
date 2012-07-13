class Egems.Views.TimeEntry extends Backbone.View
  template: JST['timesheets/time_entry']
  tagName: 'tr'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      timeEntry: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
      size: @model.collection.length
    ))
    this
