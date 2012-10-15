class Egems.Views.EditHoliday extends Backbone.View

  template: JST['holidays/edit']

  initialize: ->
    @form   = new Egems.Views.HolidayForm(model: @model, action: "update")

  events: ->
    "click #holiday-form-actions button.submit" : "submitForm"

  render: ->
    $(@el).html(@template())
    if this.options.modal == true
      @newHolidayModal()
    this

  newHolidayModal: ->
    @$('#edit-holiday-header').wrap('<div class="modal-header" />')
    @$('#holiday-form-container').addClass('modal-body')
                                 .append(@form.render().el)
    @$('#holiday-form-actions').addClass('modal-footer')

  submitForm: (event) ->
    event.preventDefault()
    edit_path = "/hr/holidays/edit/" + @model.getId().toString()
    @$("#holiday-form").attr('action', edit_path).submit()
