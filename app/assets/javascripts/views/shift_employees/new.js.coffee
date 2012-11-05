class Egems.Views.NewShiftScheduleEmployee extends Backbone.View

  template: JST['shift_employees/new']
  className: "semi-modal"

  events: ->
    "click button.cancel" : "cancelAdd"
    "click button.submit" : "addEmployee"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults)
    @shift  = this.options.shift

  render: ->
    $(@el).html(@template)
          .attr('id', 'new-shift-employee-container')
    @initFields()
    @initData()
    @employees.each @appendToSelect
    this

  initFields: ->
    @form      = @$("#new-shift-employee-form")
    @selectFld = @$("select[name='employee[employee_id]']")
    @fromFld   = @$("input[name='employee[start_date]']")
    @toFld     = @$("input[name='employee[end_date]']")
    @selectFld.attr('disabled', true)
    @fromFld.attr('readonly', true)
    @toFld.attr('readonly', true)

    today = new Date()
    @dateSelector(@fromFld, { minDate: today })
    @dateSelector(@toFld, { minDate: today })

    @fromFld.val(@format_date(today))
    @toFld.val(@format_date(today))

  initData: ->
    @employees = new Egems.Collections.Employees()
    @employees.fetch
      url: '/employee_mappings'
      async: false
      success: (collection, response) =>
        @selectFld.attr('disabled', false)
        @employees.reset(response.employees)
        @employees.each @appendToSelect

  appendToSelect: (employee) =>
    @selectFld.append("<option value='#{ employee.id }'>#{ employee.fullName() }</option>")


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

  cancelAdd: (event) ->
    event.preventDefault()
    @remove()

  addEmployee: (event) ->
    event.preventDefault()
    $.ajax
      url: "/hr/shifts/#{ @shift.id }/employees/new"
      data: @form.serialize()
      dataType: 'JSON'
      type: 'POST'
      success: (data) =>
        @container = $("#shift_#{ @shift.id }_employees_container")
        if data.errors != undefined
          @flashMsg data.errors
        else
          shift = new Egems.Models.ShiftSchedule(data.shift)
          view = new Egems.Views.ShiftScheduleEmployees(model: shift)
          @container.html(view.render().el)
          @flashMsg data.success

  flashMsg: (msg) ->
    @container.find("#flash_messages").html(@flash_messages(msg))
