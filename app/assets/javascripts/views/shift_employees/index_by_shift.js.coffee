class Egems.Views.ShiftScheduleEmployees extends Backbone.View

  template: JST['shift_employees/index_by_shift']
  shiftView: JST['shift_schedules/shift']
  employeeRow: JST['shift_employees/employee_by_shift']

  events: ->
    "click #add-shift-employee-btn" : "addEmployee"

  initialize: ->
    @tableId = "shift_#{ @model.getId() }_employees"
    @mixins  = _.extend(this, Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@shiftView(shift: @model))
          .attr('id', "#{ @tableId }_container")
    @getEmployees()
    view = $(@template(employees: @collection))
    view.closest("table").attr("id", @tableId)
    $(@el).append(view)
    this

  getEmployees: ->
    @collection = new Egems.Collections.ShiftScheduleEmployees({ shiftId: @model.getId() })
    @collection.reset()
    @collection.on('add', @showEmployee, this)
    @collection.fetch
      add: true

  showEmployee: (employee) ->
    nodata = $("##{ @tableId } tbody tr.nodata")
    if nodata.length > 0
      nodata.remove()

    view = @employeeRow(employee: employee, mixins: @mixins)
    @$("##{ @tableId } tbody").append(view)

  addEmployee: (event) ->
    event.preventDefault()
    view = new Egems.Views.NewShiftScheduleEmployee(shift: @model)
    if $("#new-shift-employee-container").length == 0
      $("##{ @tableId }").before(view.render().el)
