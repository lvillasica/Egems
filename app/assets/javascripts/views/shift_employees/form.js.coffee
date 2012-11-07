class Egems.Views.ShiftScheduleEmployeeForm extends Backbone.View

  template: JST['shift_employees/form']
  className: "semi-modal"

  events: ->
    "click button.cancel" : "closeForm"
    "click button.submit" : "submitForm"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults)
    @action = this.options.action
    @actionHeader = @capitalize @action
    @shiftId = @model.shiftId()

  render: ->
    $(@el).html(@template(
      actionHeader: @actionHeader
    ))
    @initFields()
    @setupEmployees()
    this

  initFields: ->
    @container = $("div.shift-employees-container")
    @msgsDiv   = @container.find("#flash_messages")
    @form      = $(@el).find("form")
    @selectFld = @$("select[name='employee[employee_id]']")
    @fromFld   = @$("input[name='employee[start_date]']")
    @toFld     = @$("input[name='employee[end_date]']")
    @selectFld.attr('disabled', true)
    @fromFld.attr('readonly', true)
    @toFld.attr('readonly', true)

    if @action is "update"
      @fromFld.val(@format_date @model.startDate())
      @toFld.val(@format_date @model.endDate())

    yearStart = new Date(new Date().getFullYear(), 0, 1)
    @dateSelector(@fromFld, { minDate: yearStart })
    @dateSelector(@toFld, { minDate: yearStart })

  setupEmployees: ->
    if @action is "create"
      @employees = new Egems.Collections.Employees()
      @employees.fetch
        url: '/employee_mappings'
        asynch: false
        success: (collection, response) =>
          @selectFld.attr('disabled', false)
          @employees.reset(response.employees)
          @employees.each @appendToSelect
    else
      id = @model.employeeId()
      name = @model.fullName()
      @selectFld.append(("<option value='#{id}'>#{name}</option>"))

  appendToSelect: (employee) =>
    @selectFld.append("<option value='#{employee.id}'>#{employee.fullName()}</option>")

  submitForm: (event) ->
    event.preventDefault()
    root_path = "/hr/shifts/#{@shiftId}/employees"
    path = if @action is "create" then "/new" else "/edit/#{@model.id}"

    $.ajax
      url: root_path + path
      type: if @action is "create" then "POST" else "PUT"
      data: @form.serialize()
      dataType: "JSON"
      success: (data) =>
        if data.errors != undefined
          @msgsDiv.html(@flash_messages(data.errors))
        else
          shift = new Egems.Models.ShiftSchedule(data.shift)
          shiftView = new Egems.Views.ShiftScheduleEmployees(model: shift)
          @container.replaceWith(shiftView.render().el)
          @msgsDiv = $("div.shift-employees-container #flash_messages")
          @msgsDiv.html(@flash_messages(data.success))

  closeForm: (event) ->
    event.preventDefault()
    @removeRowHighlights()
    @msgsDiv.empty()
    @remove()

  removeRowHighlights: ->
    employeesTable = $("#shift-#{@shiftId}-employees-tbl tbody")
    employeesTable.find('tr').each (i, row) ->
      $(row).removeClass("updating")

  dateSelector: (dateFld, moreOpts = {}, useDefaultOpts = true) ->
    defaultOpts =
      showOtherMonths: true
      selectOtherMonths: false
      showOn: "button"
      buttonText: "<i class='icon-calendar'></i>"
      dateFormat: 'yy-mm-dd'
    opts = if useDefaultOpts then $.extend(defaultOpts, moreOpts) else moreOpts
    $(dateFld).datepicker("destroy").datepicker(opts)
    $(dateFld).next('.ui-datepicker-trigger').addClass("btn")
