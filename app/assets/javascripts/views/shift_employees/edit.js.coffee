class Egems.Views.EditShiftScheduleEmployee extends Backbone.View

  className: "shift-employee-form-container"

  initialize: ->
    @shift = this.options.shift
    @form = new Egems.Views.ShiftScheduleEmployeeForm(action: 'update', model: @model)

  render: ->
    $(@el).html(@form.render().el)
    this
