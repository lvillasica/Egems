class Egems.Views.Leave extends Backbone.View
  template: JST['leaves/leave']
  tagName: 'tr'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
