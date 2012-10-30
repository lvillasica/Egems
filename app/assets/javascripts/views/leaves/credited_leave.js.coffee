class Egems.Views.CreditedLeave extends Backbone.View

  template: JST['leaves/credited_leave']
  
  tagName: 'tr'
  
  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
