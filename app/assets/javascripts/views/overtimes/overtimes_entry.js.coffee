class Egems.Views.OvertimesEntry extends Backbone.View

  template: JST['overtimes/overtimes_entry']
  tagName: 'tr'

  initialize: ->
    @model.on('change', @render, this)

  render: ->
    $(@el).html(@template(
      overtime: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
      )) 
    this