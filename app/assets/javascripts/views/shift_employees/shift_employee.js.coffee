class Egems.Views.ShiftScheduleEmployee extends Backbone.View

  template: JST['shift_employees/shift_employee']
  tagName: 'tr'

  events: ->
    "click a.edit" : "showEditForm"
    "click a.remove" : "removeEmployee"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.ShiftSchedules)
    @initDivs()

  render: ->
    $(@el).html(@template(employee: @model, mixins: @mixins))
    this

  initDivs: ->
    @templateId = "shift-#{ @model.shiftId() }-employees"
    @mainDiv = $("##{@templateId}")
    @employeesTable = $("##{@templateId}-tbl")
    @msgsDiv = @mainDiv.find("#flash_messages")

  showEditForm: (event) ->
    event.preventDefault()
    @removeRowHighlights()
    @highlightRow()
    editForm = new Egems.Views.EditShiftScheduleEmployee(model: @model)
    @msgsDiv.empty()

    formContainer = $("div.shift-employee-form-container")
    if formContainer.length == 0
      @employeesTable.before(editForm.render().el)
    else
      formContainer.replaceWith(editForm.render().el)

  removeRowHighlights: ->
    @employeesTable.find('tbody tr').each (i, row) ->
      $(row).removeClass("updating")

  highlightRow: ->
    $(@el).addClass("updating")

  removeEmployee: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      $.ajax
        url: "/hr/shifts/#{@model.shiftId()}/employees/delete/#{@model.id}"
        type: "DELETE"
        dataType: "JSON"
        success: (data) =>
          if data.errors != undefined
            @msgsDiv.html(@flash_messages(data.errors))
          else
            @remove()
            $(".shift-employee-form-container").remove()
            @msgsDiv.html(@flash_messages(data.success))
            shift = new Egems.Models.ShiftSchedule(data.shift)
            @checkEmptyTable(shift)

  checkEmptyTable: (shift) ->
    if @employeesTable.find('tbody tr').length == 0
      @employeesTable.append "<tr><td colspan='4' class='well'><em>No data found.</em></td></tr>"
      rowId = shift.id
      view = new Egems.Views.ShiftSchedule(model: shift)
      $("#shift_#{rowId}").replaceWith(view.render().el)
      $(".shift_#{rowId}_details").remove()
