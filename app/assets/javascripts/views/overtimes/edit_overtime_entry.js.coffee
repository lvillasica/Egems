class Egems.Views.EditOvertimeEntry extends Backbone.View

  template: JST['overtimes/edit_overtime_entry']

  events:
    "click #edit-overtime-actions .submit" : "triggerSubmit"

  initialize: ->
    @form = new Egems.Views.OvertimeForm
      model: @model
      edit: true
      oldData: @options.oldData

  render: ->
    $(@el).html(@template())
    @$("#edit-overtime-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#overtime-form").attr("action", "/overtimes/#{ @model.id }").submit()

  showOvertimeForm: ->
    $('#overtime-form-modal').append(this.render().el)
    $('#edit-overtime-header').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#edit-overtime-container').addClass('modal-body')
    $('#edit-overtime-actions').addClass('modal-footer')
    $('#edit-overtime-actions .cancel').attr('data-dismiss', 'modal')
    $('#overtime-form-modal').modal(backdrop: 'static', 'show')
    $('#overtime-form-modal').on 'hidden', ->
      $(this).remove()
