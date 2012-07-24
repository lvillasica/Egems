class Egems.Views.LeaveDetailForm extends Backbone.View
  
  template: JST['leave_details/leave_detail_form']
  
  events:
    'click #radio-reset-btn': 'resetPeriod'
    'click #leave_detail_form .cancel': 'navigateLeaves'
    'submit #leave_detail_form': 'submitForm'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @leaveTypeFld = null
    @leaveDateFld = null
    @endDateFld = null
    @leaveUnitFld = null
    @minDate = null
    @maxDate = null
    @startDate = null
    @endDate = null
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
  
  setFormValues: ->
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
      else
        @minDate = new Date(@model.leaveStartDate())
        @maxDate = new Date(@model.leaveEndDate())
        @setDateFldVal(@leaveDateFld, new Date())
        @setDateFldVal(@endDateFld, new Date())
    @validateDateFld @leaveDateFld
    @validateDateFld @endDateFld
    @dateSelector(@leaveDateFld, {minDate: @minDate, maxDate: @maxDate})
    @dateSelector(@endDateFld, {minDate: @leaveDateFld.val(), maxDate: @maxDate})
    @setLeaveUnitFldVal()
    @setHalfDay()
  
  setDateFldVal: (dateFld, newDateVal) ->
    fldDateVal = Date.parse(dateFld.val()) or new Date()
    if fldDateVal >= @minDate and fldDateVal <= @maxDate
      dateFld.val(@format_date fldDateVal)
    else
      dateFld.val(@format_date newDateVal)
  
  setLeaveUnitFldVal: ->
    offset = if @isHalfDay() then 0.5 else 1
    @setDates()
    days = ((@endDate - @startDate) / 1000 / 60 / 60 / 24)
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
  
  resetDates: ->
    if @validDates()
      @setDates()
      if @startDate > @endDate
        @endDateFld.val(@leaveDateFld.val())
      else if @startDate > @maxDate
        @leaveDateFld.val(@format_date @maxDate)
      else if @startDate < @minDate
        @leaveDateFld.val(@format_date @minDate)
      else if @endDate > @maxDate
        @endDateFld.val(@format_date @maxDate)
      @dateSelector(@endDateFld, {minDate: @startDate, maxDate: @maxDate})
      @setHalfDay()
      @setLeaveUnitFldVal()
  
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
    @model.set attributes
    $.ajax
      url: '/leave_details'
      data: {'leave_detail': attributes}
      dataType: 'json'
      type: 'POST'
      beforeSend: (jqXHR, settings) =>
        $('#leave_detail_form .cancel').attr('disabled', true) if @inModal()
      complete: (jqXHR, textStatus) =>
        $('#leave_detail_form .cancel').removeAttr('disabled') if @inModal()
      success: (data) =>
        flash_messages = data.flash_messages
        if flash_messages.error is undefined
          @navigateLeaves(event)
          $("#main-container").prepend(@flash_messages(flash_messages))
          @updateNotif(data.total_pending)
        else
          $('#flash_messages').html(@flash_messages(flash_messages))
  
  navigateLeaves: (event) ->
    event.preventDefault()
    if @inModal()
      if $('#leave_detail_form .cancel').attr('disabled') is undefined
        $('#apply-leave-modal').modal('hide')
        if event.type is 'submit'
          leaves = new Egems.Routers.Leaves()
          leaves.index()
    else
      leaves = new Egems.Routers.Leaves()
      leaves.navigate('leaves', true)
  
  inModal: ->
    $('#leave_detail_form').parents('#apply-leave-modal').length == 1

  updateNotif: (totalPending) ->
    popoverContent = "You have #{ totalPending } leaves waiting for approval."
    $('#notif').attr('data-content', popoverContent)
    $('#total_pending_leaves').html(totalPending)

