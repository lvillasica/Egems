class Egems.Views.LeaveRequest extends Backbone.View

  template: JST['leave_requests/leave_detail']
  tagName: 'tr'

  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
