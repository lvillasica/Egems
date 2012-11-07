class Egems.Views.ShiftScheduleEmployees extends Backbone.View

  className: "shift-employees-container"
  template: JST['shift_employees/index']

  events: ->
    "click a.root" : "gotoShiftsIndex"
    "click #add-shift-employee-btn" : "showAddForm"

  initialize: ->
    @templateId = "shift-#{ @model.id }-employees"
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.ShiftSchedules)
    @getEmployees()

  render: ->
    $(@el).html(@template(employees: @collection))
    @initDivs()
    this

  initDivs: ->
    @main = $(@el).first()
    @main.attr('id', @templateId)
    @employeesTable = @main.find("table.shift-employees")
    @employeesTable.attr("id", "#{@templateId}-tbl")

  getEmployees: ->
    @collection = new Egems.Collections.ShiftScheduleEmployees({ shiftId: @model.id })
    @collection.reset()
    @collection.on('add', @showEmployee, this)
    @collection.fetch
      add: true

  showEmployee: (employee) ->
    nodata = @employeesTable.find("tbody tr.nodata")
    if nodata.length > 0
      nodata.remove()

    e = new Egems.Views.ShiftScheduleEmployee(model: employee)
    @employeesTable.find("tbody").append(e.render().el)

  showAddForm: (event) ->
    event.preventDefault()
    newForm = new Egems.Views.NewShiftScheduleEmployee(shift: @model)
    @main.find("#flash_messages").empty()

    formContainer = $("div.shift-employee-form-container")
    if formContainer.length == 0
      @employeesTable.before(newForm.render().el)
    else
      formContainer.replaceWith(newForm.render().el)

  gotoShiftsIndex: (event) ->
    event.preventDefault()
    @slideEffect($(@el), $("#shifts-index-container"), { complete: => @remove() })
