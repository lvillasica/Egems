class Egems.Views.EditLeaveDetail extends Backbone.View

  template: JST['leave_details/edit_leave_detail']

  events:
    'click #leave-detail-form-actions .cancel': 'exitForm'
    'click #leave-detail-form-actions .submit': 'triggerSubmit'

  initialize: ->
    @form = new Egems.Views.LeaveDetailForm(model: @model, edit: true)

  render: ->
    $(@el).html(@template())
    if @model.employeeLeaves() != undefined
      @$("#leave-application-container").append(@form.render().el)
    else
      _.extend(this, Egems.Mixins.Leaves)
      flashMsgs = $("#data-container").data('flash-messages')
      $(@el).append(@noLeaveModal(flashMsgs, isModal: false))
      @$("#leave-detail-form-actions").remove()
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$('#leave_detail_form').attr('action', "/leave_details/#{@model.getId()}")
    .submit()

  exitForm: (event) ->
    @form.exitForm(event)
