class Egems.Views.LeaveDetail extends Backbone.View
  template: JST['leave_details/leave_detail']
  tagName: 'tr'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      leave_detail: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
