class Egems.Views.ShiftScheduleEmployee extends Backbone.View

  template: JST['shift_employees/shift_employee']
  tagName: 'tr'

  events: ->
    "click a.remove" : "removeEmployee"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.ShiftSchedules)
    @tableId = "shift_#{ @model.shiftId() }_employees"

  render: ->
    $(@el).html(@template(employee: @model, mixins: @mixins))
    this

  removeEmployee: (event) ->
    event.preventDefault()
    $.ajax
      url: "/hr/shifts/#{@model.shiftId()}/employees/delete/#{@model.id}"
      dataType: 'JSON'
      type: 'DELETE'
      success: (data) =>
        if data.errors != undefined
          @flashMsg data.errors
        else
          @remove()
          @flashMsg data.success

  flashMsg: (msg) ->
    $("##{ @tableId }").find("#flash_messages").html(@flash_messages(msg))
