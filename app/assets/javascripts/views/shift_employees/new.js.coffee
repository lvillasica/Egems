class Egems.Views.NewShiftScheduleEmployee extends Backbone.View

  className: "shift-employee-form-container"

  initialize: ->
    shift = this.options.shift
    @model = new Egems.Models.ShiftScheduleEmployee({ shift_schedule_id: shift.id })
    @form = new Egems.Views.ShiftScheduleEmployeeForm(action: 'create', model: @model)

  render: ->
    $(@el).html(@form.render().el)
    this
