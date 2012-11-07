class Egems.Views.EditShiftSchedule extends Backbone.View

  template: JST['shift_schedules/edit']
  id: 'shift-form-container-wrapper'

  events: ->
    'click .root' : 'cancelForm'
    'click #shift-form-actions a.cancel' : 'cancelForm'
    'click #shift-form-actions button.submit' : 'submitForm'

  initialize: ->
    @form  = new Egems.Views.ShiftScheduleForm(model: @model, action: 'update')
    _.extend(this, Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@template)
    if this.options.modal == true
      @editShiftScheduleModal()
    else
      @editShiftSchedule()
    this

  editShiftSchedule: ->
    @$("#shift-form-container").append(@form.render().el)

  editShiftScheduleModal: ->
    @$('#edit-shift-header').wrap('<div class="modal-header" />')
    @$('#shift-form-container').addClass('modal-body')
                               .append(@form.render().el)
    @$('#shift-form-actions').addClass('modal-footer')

  submitForm: (event) ->
    event.preventDefault()
    edit_path = "/hr/shifts/edit/" + @model.getId().toString()
    @$("#shift-form").attr('action', edit_path).submit()

  cancelForm: (event) ->
    event.preventDefault()
    @slideEffect($(@el), $("#shifts-index-container"), { complete: => @remove() })
