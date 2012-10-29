class Egems.Views.EditShiftSchedule extends Backbone.View

  template: JST['shift_schedules/edit']

  events: ->
    'click #shift-form-actions button.submit' : 'submitForm'

  initialize: ->
    @form  = new Egems.Views.ShiftScheduleForm(model: @model, action: 'update')

  render: ->
    $(@el).html(@template)
    if this.options.modal == true
      @editShiftScheduleModal()
    this

  editShiftScheduleModal: ->
    @$('#edit-shift-header').wrap('<div class="modal-header" />')
    @$('#shift-form-container').addClass('modal-body')
                               .append(@form.render().el)
    @$('#shift-form-actions').addClass('modal-footer')

  submitForm: (event) ->
    event.preventDefault()
    edit_path = "/hr/shifts/edit/" + @model.getId().toString()
    @$("#shift-form").attr('action', edit_path).submit()
