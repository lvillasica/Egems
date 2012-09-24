class Egems.Views.NewOvertimeEntry extends Backbone.View

  template: JST['overtimes/new_overtime_entry']

  events:
    "click #overtime-application-actions .submit" : "triggerSubmit"

  initialize: ->
    @form = new Egems.Views.OvertimeForm(model: @model)

  render: ->
    $(@el).html(@template())
    @$("#overtime-application-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#overtime-form").attr("action", "/overtimes").submit()

  showOvertimeForm: ->
    $('#overtime-form-modal').append(this.render().el)
    $('#overtime-application-header').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#overtime-application-container').addClass('modal-body')
    $('#overtime-application-actions').addClass('modal-footer')
    $('#overtime-application-actions .cancel').attr('data-dismiss', 'modal')
    $('#overtime-form-modal').modal(backdrop: 'static', 'show')
    $('#overtime-form-modal').on 'hidden', ->
      $(this).remove()
