class Egems.Views.LeaveDetailForm extends Backbone.View

  template: JST['leave_details/leave_detail_form']

  events:
    'click #radio-reset-btn': 'resetPeriod'
    'submit #leave_detail_form': 'submitForm'

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Leaves)
    @leaves = @options.leaves
    @oldData = @options.oldData
    @leaveTypeFld = null
    @leaveDateFld = null
    @endDateFld = null
    @leaveUnitFld = null
    @minDate = null
    @maxDate = null
    @startDate = null
    @endDate = null
    @model.on('change:leave_type', @getMinMaxDates, this)
    @model.on('change:leave_type', @setFormValues, this)
    @model.on('change:leave_date', @resetDates, this)
    @model.on('change:end_date', @resetDates, this)
    @model.on('change:leave_unit', @setLeaveUnitFldVal, this)
    @model.on('change:period', @setHalfDay, this)

  render: ->
    $(@el).html(@template(
      leave_detail: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initFields()
    @setFormValues()
    this

  initFields: ->
    @leaveTypeFld = @$('#leave_detail_leave_type')
    @leaveDateFld = @$('#leave_detail_leave_date')
    @endDateFld = @$('#leave_detail_end_date')
    @leaveUnitFld = @$('#leave_detail_leave_unit')
    @periodFld = @$("#leave_detail_form input[name='leave_detail[period]']")
    @detailsFld = @$("#leave_detail_details")
    @leaveTypeFld.change => @model.set('leave_type', @leaveTypeFld.val())
    @leaveDateFld.change => @model.set('leave_date', @leaveDateFld.val())
    @endDateFld.change => @model.set('end_date', @endDateFld.val())
    @leaveUnitFld.change => @model.set('leave_unit', @leaveUnitFld.val())
    @periodFld.change => @model.set('period', @periodFld.filter(':checked').val())

  dateSelector: (dateFld, moreOpts = {}, useDefaultOpts = true) ->
    defaultOpts =
      showOtherMonths: true
      selectOtherMonths: true
      showOn: "button"
      buttonText: "<i class='icon-calendar'></i>"
      dateFormat: 'yy-mm-dd'
      onSelect: @onDateSelect
    opts = if useDefaultOpts then $.extend(defaultOpts, moreOpts) else moreOpts
    $(dateFld).datepicker("destroy").datepicker(opts)
    $(dateFld).next('.ui-datepicker-trigger').addClass("btn")

  onDateSelect: (dateText, inst) =>
    @model.set(inst.id.substring(13), dateText)

  getMinMaxDates: ->
    $.ajax
      url: '/leave_details/new'
      data: { 'leave_type': @leaveTypeFld.val() }
      async: false
      dataType: 'JSON'
      success: (data) =>
        @model.set('leave_start_date', data.leave_detail['leave_start_date'])
        @model.set('leave_end_date', data.leave_detail['leave_end_date'])

  setFormValues: ->
    @leaveTypeFld.attr('disabled', true) if @options.edit
    switch @leaveTypeFld.val()
      when "Vacation Leave"
        @minDate = new Date().addDays(1)
        @maxDate = new Date(@model.leaveEndDate())
        @setDateFldVal(@leaveDateFld, @minDate)
        @setDateFldVal(@endDateFld, @minDate)
      when "Sick Leave", "Emergency Leave"
        @minDate = new Date(@model.leaveStartDate())
        @maxDate = new Date()
        @setDateFldVal(@leaveDateFld, @maxDate)
        @setDateFldVal(@endDateFld, @maxDate)
      when "Maternity Leave", "Magna Carta"
        @minDate = new Date().addDays(1)
        @maxDate = new Date().addYears(1)
        dateWithAllocation = new Date().addDays(1 + @model.employeeLeaves()[@leaveTypeFld.val()])
        @setDateFldVal(@leaveDateFld, @minDate)
        @setDateFldVal(@endDateFld, dateWithAllocation)
      else
        @minDate = new Date(@model.leaveStartDate())
        @maxDate = new Date(@model.leaveEndDate())
        @setDateFldVal(@leaveDateFld, new Date())
        @setDateFldVal(@endDateFld, new Date())
    @setPeriodFldVal()
    @validateDateFld @leaveDateFld
    @validateDateFld @endDateFld
    @dateSelector(@leaveDateFld, {minDate: @minDate, maxDate: @maxDate})
    @dateSelector(@endDateFld, {minDate: @leaveDateFld.val(), maxDate: @maxDate})
    @setLeaveUnitFldVal()
    @disableAttr()
    @setHalfDay()
  
  setPeriodFldVal: ->
    @$("#leave_detail_period_#{@model.period()}").attr('checked', 'checked')

  setDateFldVal: (dateFld, newDateVal) ->
    fldDateVal = Date.parse(dateFld.val()) or new Date()
    if fldDateVal >= @minDate and fldDateVal <= @maxDate
      dateFld.val(@format_date fldDateVal)
    else
      dateFld.val(@format_date newDateVal)
    dateFld.val(@format_date newDateVal) if _.include(@calendarLeaves(), @leaveTypeFld.val())

  setLeaveUnitFldVal: ->
    offset = if @isHalfDay() then 0.5 else 1
    @setDates()
    days = ((@endDate - @startDate) / 1000 / 60 / 60 / 24)
    if _.include(@calendarLeaves(), @leaveTypeFld.val())
      leaveUnit = parseFloat(days).toFixed(1)
    else
      leaveUnit = parseFloat((days + offset) - @nonWorkingDays().length).toFixed(1)

    if leaveUnit >= 0
      @leaveUnitFld.val(leaveUnit)
    else
      @leaveUnitFld.val(parseFloat(0.0).toFixed(1))

  setDates: ->
    @startDate = Date.parse(@leaveDateFld.val())
    @endDate = Date.parse(@endDateFld.val())

  nonWorkingDays: ->
    current = @startDate.clone()
    result = new Array()
    while current <= @endDate
      tmpDay = current.clone()
      for obj in @model.dayOffs()
        from = Date.parse(obj.from)
        to = Date.parse(obj.to)
        days = obj.days
        result.push(tmpDay) if tmpDay >= from && tmpDay <= to && $.inArray(tmpDay.getDay(), days) != -1

      for obj in @model.holidays()
        holiday = new Date(obj.date)
        if tmpDay.clone().clearTime().equals(holiday.clone().clearTime())
          result.push(tmpDay) if $.inArray(tmpDay, result) == -1

      current.addDays(1)
    return result

  isHalfDay: ->
    @$("#leave_detail_form input[name='leave_detail[period]']:checked").length is 1

  setHalfDay: ->
    if @isHalfDay()
      @$('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', true)
      if @validDates()
        @endDateFld.val(@leaveDateFld.val())
        @setLeaveUnitFldVal()

  resetPeriod: ->
    $("#leave_detail_form input[name='leave_detail[period]']").attr('checked', false)
    $('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', false)
    @setLeaveUnitFldVal() if @validDates()
    @model.set('period', 0)
    return false

  disableAttr: ->
    if _.include(@calendarLeaves(), @leaveTypeFld.val())
      @$("#leave_detail_form input[name='leave_detail[period]']").attr('disabled', true)
      @$('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', true)
      @$("#radio-reset-btn.btn.btn-mini").attr('disabled', true)
      @$('#leave_detail_end_date').attr('disabled', true)
      @$('#leave_detail_leave_unit').attr('disabled', true)
    else
      @$("#leave_detail_form input[name='leave_detail[period]']").removeAttr('disabled')
      @$('#leave_detail_end_date').next('.ui-datepicker-trigger').removeAttr('disabled')
      @$("#radio-reset-btn.btn.btn-mini").removeAttr('disabled')
      @$('#leave_detail_end_date').removeAttr('disabled')
      @$('#leave_detail_leave_unit').removeAttr('disabled')

  resetDates: ->
    if @validDates()
      @setDates()
      if !_.include(@calendarLeaves, @leaveTypeFld.val())
        if @startDate > @endDate
          @endDateFld.val(@leaveDateFld.val())
        else if @startDate > @maxDate
          @leaveDateFld.val(@format_date @maxDate)
        else if @startDate < @minDate
          @leaveDateFld.val(@format_date @minDate)
        else if @endDate > @maxDate
          @endDateFld.val(@format_date @maxDate)
      @updateEndDateWithAllocation(@startDate) if _.include(@calendarLeaves(), @leaveTypeFld.val())
      @dateSelector(@endDateFld, {minDate: @startDate, maxDate: @maxDate})
      @setHalfDay()
      @setLeaveUnitFldVal()
      @disableAttr()

  calendarLeaves: ->
    leaves = ["Magna Carta", "Maternity Leave"]

  updateEndDateWithAllocation: (date) ->
    newDate = date.addDays(@model.employeeLeaves()[@leaveTypeFld.val()])
    @setDateFldVal(@endDateFld,newDate)


  validDates: ->
    validLeaveDate = @validateDateFld(@leaveDateFld)
    validEndDate = @validateDateFld(@endDateFld)
    return validLeaveDate and validEndDate

  validateDateFld: ( field ) ->
    if Date.parse(field.val()) is null || @validateDateFormat(field.val()) is false
      field.closest('.control-group').addClass('error')
      return false
    else
      field.closest('.control-group').removeClass('error')
      return true

  validateDateFormat: (dateStr) ->
    matches = /^(\d{4})[-](\d{1,2})[-](\d{1,2})$/.exec(dateStr)
    res = if matches is null then false else true
    return res

  submitForm: (event) ->
    event.preventDefault()
    attributes =
      'leave_type': @leaveTypeFld.val()
      'period': (@periodFld.filter(':checked').val() or 0)
      'leave_date': @leaveDateFld.val()
      'end_date': @endDateFld.val()
      'leave_unit': @leaveUnitFld.val()
      'details': @detailsFld.val()
    $.ajax
      url: @$("#leave_detail_form").attr('action')
      data: {'leave_detail': attributes}
      dataType: 'json'
      type: if @options.edit then 'PUT' else 'POST'
      beforeSend: (jqXHR, settings) =>
        @disableFormActions() if @inModal()
      success: (data) =>
        @oldData.set attributes if @oldData
        @enableFormActions() if @inModal()
        flash_messages = data.flash_messages
        if flash_messages.error is undefined
          @exitForm(event, data)
          @updateNotif(data.total_pending)
        else
          $('#flash_messages').html(@flash_messages(flash_messages))

  exitForm: (event, data = null) ->
    event.preventDefault()
    if @inModal()
      if $('#leave-detail-form-actions .cancel').attr('disabled') is undefined
        $('#apply-leave-modal').modal('hide')
        if event.type is 'submit'
          if Backbone.history.fragment is 'leaves'
            if @options.edit
              leave = @leaves.get(@oldData.leaveId())
              leave.set
                total_pending: data.leave_detail.leave_total_pending
                remaining_balance: data.leave_detail.leave_remaining_balance
              @showFlash(data.flash_messages)
              @oldData.trigger 'highlight'
            else
              leaves = new Egems.Routers.Leaves()
              leaves.index()
              @showFlash(data.flash_messages)
          else
            timesheets = new Egems.Routers.Timesheets()
            timesheets.index()
            @showFlash(data.flash_messages)
    else
      leaves = new Egems.Routers.Leaves()
      leaves.navigate('leaves', true)
      @showFlash(data.flash_messages)

  inModal: ->
    $('#leave_detail_form').parents('#apply-leave-modal').length == 1
  
  showFlash: (flash_messages) ->
    $("#main-container").prepend(@flash_messages(flash_messages))
    $('html, body').animate({scrollTop: 0}, 'slow')
  
  enableFormActions: ->
    $('#leave-detail-form-actions .submit').removeAttr('disabled')
    $('#leave-detail-form-actions .cancel').removeAttr('disabled')
  
  disableFormActions: ->
    $('#leave-detail-form-actions .submit').attr('disabled', true)
    $('#leave-detail-form-actions .cancel').attr('disabled', true)

