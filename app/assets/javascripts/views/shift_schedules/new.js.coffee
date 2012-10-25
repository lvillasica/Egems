class Egems.Views.NewShiftSchedule extends Backbone.View

  template: JST['shift_schedules/new']

  events: ->
    'click #shift-form-actions button.submit' : 'submitForm'

  initialize: ->
    @model = new Egems.Models.ShiftSchedule()
    @form  = new Egems.Views.ShiftScheduleForm(model: @model, action: 'create')

  render: ->
    $(@el).html(@template)
    if this.options.modal == true
      @newShiftScheduleModal()
    this

  newShiftScheduleModal: ->
    @$('#new-shift-header').wrap('<div class="modal-header" />')
    @$('#shift-form-container').addClass('modal-body')
                               .append(@form.render().el)
    @$('#shift-form-actions').addClass('modal-footer')

  submitForm: (event) ->
    event.preventDefault()
    @$("#shift-form").attr('action', '/hr/shifts/new').submit()
