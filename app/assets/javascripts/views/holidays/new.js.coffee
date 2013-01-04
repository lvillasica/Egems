class Egems.Views.NewHoliday extends Backbone.View

  template: JST['holidays/new']

  initialize: ->
    @date   = this.options.defaultDate
    @model  = new Egems.Models.Holiday()
    @form   = new Egems.Views.HolidayForm(model: @model, action: "create", date: @date)

  events: ->
    "click #holiday-form-actions button.submit" : "submitForm"

  render: ->
    $(@el).html(@template())
    if this.options.modal == true
      @newHolidayModal()
    this

  newHolidayModal: ->
    @$('#new-holiday-header').wrap('<div class="modal-header" />')
    @$('#holiday-form-container').addClass('modal-body')
                                 .append(@form.render().el)
    @$('#holiday-form-actions').addClass('modal-footer')

  submitForm: (event) ->
    event.preventDefault()
    @$("#holiday-form").attr('action', '/hr/holidays/new').submit()
