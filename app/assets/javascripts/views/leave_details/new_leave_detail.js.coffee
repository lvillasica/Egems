class Egems.Views.NewLeaveDetail extends Backbone.View

  template: JST['leave_details/new_leave_detail']

  events:
    'click #leave-detail-form-actions .cancel': 'navigateLeaves'
    'click #leave-detail-form-actions .submit': 'triggerSubmit'

  initialize: ->
    @form = new Egems.Views.LeaveDetailForm(model: @model)

  render: ->
    $(@el).html(@template())
    if @model.employeeLeaves() != undefined
      @$("#new-leave-application-container").append(@form.render().el)
    else
      _.extend(this, Egems.Mixins.Leaves)
      flashMsgs = $("#data-container").data('flash-messages')
      $(@el).append(@noLeaveModal(flashMsgs, isModal: false))
      @$("#leave-detail-form-actions").remove()
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$('#leave_detail_form').attr('action', '/leave_details').submit()

  navigateLeaves: (event) ->
    @form.navigateLeaves(event)
