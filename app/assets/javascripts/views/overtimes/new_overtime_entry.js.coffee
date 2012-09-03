class Egems.Views.NewOvertimeEntry extends Backbone.View

  template: JST['overtimes/new_overtime_entry']

  events:
    "click #overtime-action .submit" : "triggerSubmit"
    "click #overtime-action .cancel" : "closeForm"

  initialize: ->
    @form = new Egems.Views.OvertimeForm(model: @model)

  render: ->
    $(@el).html(@template())
    @$("#overtime-application-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#overtime-form").attr("action","/overtimes").submit()

  showOvertimeForm: (data) ->
    $('#apply-overtime-modal').append(this.render().el)
    $('#overtime-application-header').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#overtime-application-container').addClass('modal-body')
    $('#overtime-detail-form-actions').addClass('modal-footer')
    $('#apply-overtime-modal').modal(backdrop: 'static', 'show')
    $('#apply-overtime-modal').on 'hidden', ->
      $(this).remove()

  closeForm: (event) ->
    event.preventDefault()
    $('#apply-overtime-modal').modal('toggle')
