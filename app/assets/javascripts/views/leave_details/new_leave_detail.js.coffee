class Egems.Views.NewLeaveDetail extends Backbone.View

  template: JST['leave_details/new_leave_detail']
  
  events:
    'click #leave-detail-form-actions .cancel': 'navigateLeaves'
    'click #leave-detail-form-actions .submit': 'triggerSubmit'
  
  initialize: ->
    @form = new Egems.Views.LeaveDetailForm(model: @model)
  
  render: ->
    $(@el).html(@template())
    @$("#new-leave-application-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$('#leave_detail_form').attr('action', '/leave_details').submit()
  
  navigateLeaves: (event) ->
    @form.navigateLeaves(event)
