class Egems.Views.SpecialTypeLeaveForm extends Backbone.View
  
  template: JST['leaves/special_type_leave_form']

  events:
    'submit #leave-form': 'submitForm'

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @employees = new Egems.Collections.Employees()
    @special_types = ['Maternity Leave', 'Paternity Leave', 'Magna Carta', 'Solo Parent Leave', 'Violence Against Women']

  render: ->
    $(@el).html(@template(
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initFields()
    @initValues()
    @initDatePickers()
    this
  
  initFields: ->
    @nameFld = @$('select[name="employee[id]"]')
    @typeFld = @$('select[name="leave[leave_type]"]')
    @fromFld = @$('input[name="leave[date_from]"]')
    @toFld = @$('input[name="leave[date_to]"]')
    @allocFld = @$('input[name="leave[leaves_allocated]"]')
    @wDocsFld = @$('input[name="leave[w_docs]"]')
    this
  
  initValues: ->
    if @model and @options.edit
      id = @model.employeeId()
      @nameFld.append("<option value='#{ id }'>#{ @model.employeeName() }</option>")
      .attr('disabled', true)
      @typeFld.append("<option value='#{ @model.leaveType() }'>#{ @model.leaveType() }</option>")
      .attr('disabled', true)
      @fromFld.val @format_date @model.dateFrom()
      @toFld.val @format_date @model.dateTo()
      @allocFld.val @format_float @model.leavesAllocated()
      @wDocsFld.attr('checked', @model.wDocs())
    else
      @setEmployeeNameFld()
      @setTypeFld()
    this
  
  setEmployeeNameFld: ->
    if @employees.length is 0
      @showTinyLoadingAt(@nameFld)
      @fromFld.attr('disabled', true)
      @toFld.attr('disabled', true)
      @allocFld.attr('disabled', true)
      @employees.fetch
        url: '/employees/regularized'
        success: @resetEmployees
    else
      @removeTinyLoadingAt(@nameFld)
      @fromFld.removeAttr('disabled')
      @toFld.removeAttr('disabled')
      @allocFld.removeAttr('disabled')
      @employees.each @populateEmployeesFld
  
  resetEmployees: (collection, response) =>
    @employees.reset(response.employees)
    @setEmployeeNameFld()
  
  populateEmployeesFld: (employee) =>
    @nameFld.append("<option value='#{ employee.id }'>#{ employee.fullName() }</option>")
  
  setTypeFld: ->
    _.each @special_types, (leave_type) =>
      @typeFld.append("<option value='#{ leave_type }'>#{ leave_type }</option>")
  
  initDatePickers: ->
    @dateSelector(@fromFld, {minDate: new Date().addDays(1)})
    @dateSelector(@toFld, {minDate: new Date(@fromFld.val())})
    @fromFld.change @fromFldOnChange
  
  fromFldOnChange: (event) =>
    from = new Date(@fromFld.val())
    to = new Date(@toFld.val())
    @dateSelector(@toFld, {minDate: from})
    @toFld.val(@fromFld.val()) if from >= to
  
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
 
  getEmployeeId: ->
    if @options.edit then @model.employeeId() else @nameFld.val()
  
  getType: ->
    if @options.edit then @model.leaveType() else @typeFld.val()
 
  getParams: ->
    params = {}
    params['employee_id'] = @getEmployeeId()
    params['leave_type'] = @getType()
    params['date_from'] = @fromFld.val()
    params['date_to'] = @toFld.val()
    params['leaves_allocated'] = @allocFld.val()
    params['w_docs'] = @wDocsFld.is(':checked')
    params
  
  submitForm: (event) ->
    event.preventDefault()
    $.ajax
      url: @$("#leave-form").attr('action')
      data: { 'leave': @getParams() }
      dataType: 'json'
      type: if @options.edit then 'PUT' else 'POST'
      beforeSend: (jqXHR, settings) => @disableFormActions()
      success: @onSuccess
  
  enableFormActions: ->
    $('.submit').removeAttr('disabled')
    $('.cancel').removeAttr('disabled')
  
  disableFormActions: ->
    $('.submit').attr('disabled', true)
    $('.cancel').attr('disabled', true)
  
  onSuccess: (data) =>
    @enableFormActions()
    flash_messages = data.flash_messages
    if flash_messages.error is undefined
      @exitForm(data)
      @showFlash(data.flash_messages, null, '#other-types-of-leaves-container')
    else
      $('#flash_messages').html(@flash_messages(flash_messages))
  
  exitForm: (data) ->
    $('#leave-form-modal').modal('hide')
    if @options.edit
      @model.set(data.leave)
      @model.trigger('highlight')
    else
      @collection.add $.extend(data.leave, {employee_name: @nameFld.find(':selected').text()})

