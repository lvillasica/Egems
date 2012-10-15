class Egems.Views.EmployeeMappingForm extends Backbone.View
  
  template: JST['employee_mappings/employee_mapping_form']
  
  events:
    'submit #employee-mapping-form': 'submitForm'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @selectedEmployee = @options.selectedEmployee
    @all_mapped = @options.all_mapped
    @type = @options.type
    @employees = new Egems.Collections.Employees()

  render: ->
    $(@el).html(@template(
      type: @type
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initFields()
    @initValues()
    @initDatePickers()
    this
  
  initFields: ->
    @nameFld = @$('select[name="employee[id]"]')
    @typeFld = @$('select[name="employee_mapping[approver_type]"]')
    @fromFld = @$('input[name="employee_mapping[from]"]')
    @toFld = @$('input[name="employee_mapping[to]"]')
    this
  
  initValues: ->
    if @model and @options.edit
      id = if @type is 'Member' then @model.employeeId() else @model.approverId()
      @nameFld.append("<option value='#{ id }'>#{ @model.fullName() }</option>")
      .attr('disabled', true)
      @typeFld.val(@model.approverType()) if @typeFld
      @fromFld.val(@format_date @model.approverFrom()) if @model.approverFrom()
      @toFld.val(@format_date @model.approverTo()) if @model.approverTo()
    else
      @setEmployeeNameFld()
    this
  
  initDatePickers: ->
    @dateSelector(@fromFld)
    @dateSelector(@toFld, {minDate: new Date(@fromFld.val())})
    @fromFld.change @fromFldOnChange
  
  fromFldOnChange: (event) =>
    from = new Date(@fromFld.val())
    to = new Date(@toFld.val())
    @dateSelector(@toFld, {minDate: from})
    @toFld.val(@fromFld.val()) if from >= to
  
  setEmployeeNameFld: ->
    if @employees.length is 0
      @showTinyLoadingAt(@nameFld)
      @fromFld.attr('disabled', true)
      @toFld.attr('disabled', true)
      @employees.fetch
        url: '/employee_mappings'
        data: {'type': @type}
        success: @resetEmployees
    else
      @removeTinyLoadingAt(@nameFld)
      @fromFld.removeAttr('disabled')
      @toFld.removeAttr('disabled')
      @employees.each @populateEmployeesFld
  
  resetEmployees: (collection, response) =>
    employees = _.filter response.employees, (employee) =>
      mapped_names = _.pluck @all_mapped, 'full_name'
      unless _.contains(mapped_names, employee.full_name) or employee.full_name is @selectedEmployee.fullName()
        return employee
    @employees.reset(employees)
    @setEmployeeNameFld()
  
  populateEmployeesFld: (employee) =>
    @nameFld.append("<option value='#{ employee.id }'>#{ employee.fullName() }</option>")
  
  getApproverId: ->
    approverId = null
    switch @type
      when "Member"
        approverId = @selectedEmployee.id
      when "Supervisor/TL", "Project Manager"
        approverId = @nameFld.val()
    parseInt approverId
  
  getEmployeeId: ->
    employeeId = null
    switch @type
      when "Supervisor/TL", "Project Manager"
        employeeId = @selectedEmployee.id
      when "Member"
        employeeId = @nameFld.val()
    parseInt employeeId
  
  getType: ->
    type = @type
    if @typeFld and @type is "Member"
      type = @typeFld.val()
    type
  
  getParams: ->
    params = {}
    params['approver_id'] = if @options.edit then @model.approverId() else @getApproverId()
    params['employee_id'] = @getEmployeeId() unless @options.edit
    params['approver_type'] = @getType()
    params['from'] = @fromFld.val()
    params['to'] = @toFld.val()
    params
  
  submitForm: (event) ->
    event.preventDefault()
    $.ajax
      url: @$("#employee-mapping-form").attr('action')
      data: { 'employee_mapping': @getParams() }
      dataType: 'json'
      type: if @options.edit then 'PUT' else 'POST'
      beforeSend: (jqXHR, settings) => @disableFormActions()
      success: @onSuccess
  
  onSuccess: (data) =>
    @enableFormActions()
    flash_messages = data.flash_messages
    if flash_messages.error is undefined
      @exitForm(data)
      @showFlash(data.flash_messages, null, '#mapping-container')
    else
      $('#flash_messages').html(@flash_messages(flash_messages))
  
  exitForm: (data) ->
    $('#employee-mapping-form-modal').modal('hide')
    if @options.edit
      @model.set(data.employee_mapping)
      @model.trigger('highlight')
    else
      $('#employees-lst :selected').trigger('click')
  
  enableFormActions: ->
    $('.submit').removeAttr('disabled')
    $('.cancel').removeAttr('disabled')
  
  disableFormActions: ->
    $('.submit').attr('disabled', true)
    $('.cancel').attr('disabled', true)
    
  dateSelector: (dateFld, moreOpts = {}, useDefaultOpts = true) ->
    defaultOpts =
      showOtherMonths: true
      selectOtherMonths: true
      showOn: "button"
      buttonText: "<i class='icon-calendar'></i>"
      dateFormat: 'yy-mm-dd'
    opts = if useDefaultOpts then $.extend(defaultOpts, moreOpts) else moreOpts
    $(dateFld).datepicker("destroy").datepicker(opts)
    $(dateFld).next('.ui-datepicker-trigger').addClass("btn")

