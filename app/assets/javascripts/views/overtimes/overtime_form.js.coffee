class Egems.Views.OvertimeForm extends Backbone.View
  
  template: JST['overtimes/overtime_form']

  events:
    'submit #overtime-form': 'submitForm'

  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets, Egems.Mixins.Defaults)
    @dateFiled = @model.dateFiled()
    @dateOfOT = @model.dateOfOvertime()
    @setDuration @model.duration()
    @details = @model.details()

  initFieldVals: ->
    @durationFld = @$('input[name="overtime[duration]"]')
    @detailsFld = @$('textarea[name="overtime[work_details]"]')
    @durationFld.val(@format_in_hours @duration)
    @detailsFld.val(@details)
    this
  
  initEvents: ->
    @durationFld.focus @renderHHMMFld
    @detailsFld.focus @resetDurationFld
    this

  render: ->
    $(@el).html(@template())
    @initFieldVals()
    @initEvents()
    this
  
  setDuration: (duration) ->
    @duration = duration
    @hrs = @getHoursFromMins @duration
    @mins = @getMinsFromMins @duration
    this

  renderHHMMFld: =>
    container = @durationFld.parent()
    @durationFld.hide()
    container.append('<div id="hhmmcont" />')
    @$('#hhmmcont')
    .append('<input type="text" class="time hours" size="2" maxlength="2" placeholder="hh" /> hr(s) ')
    .append('<input type="text" class="time mins" size="2" maxlength="2" placeholder="mm" /> min(s) ')
    .append('<a class="hhmmok no_decor" href="#"><i class="icon-ok"></i></a>')
    @$("a.hhmmok").click @resetDurationFld
    @$(".time.hours").val(@hrs)
    @$(".time.mins").val(@mins)
  
  resetDurationFld: (event) =>
    event.preventDefault()
    if @$('#hhmmcont').length > 0
      @setDuration @hrsToMins(@$(".time.hours").val(), @$(".time.mins").val())
      if @validateDuration()
        @$('#hhmmcont').remove()
        @durationFld.val(@format_in_hours @duration).show()
  
  validateMins: =>
    fld = @$(".time.mins")
    val = parseInt fld.val()
    if val and val >= 60
      msg = 'min(s) field must be less than 60.'
      @showErrorAt(fld, msg)
      return false
    else
      @removeErrorAt(fld)
      return true
  
  validateDuration: ->
    if @validateMins()
      fld = @$(".time.mins")
      duration = parseInt @duration or 0
      maxDuration = @model.maxDuration()
      if duration > maxDuration
        msg = "Duration must not exceed #{ @format_in_hours maxDuration }."
        @showErrorAt(fld, msg)
        return false
      else if duration < 60
        msg = "Duration must be at least 1 hour."
        @showErrorAt(fld, msg)
        return false
      else
        @removeErrorAt(fld)
        return true
  
  showErrorAt: (fld, msg) ->
    @$('.help-inline').remove()
    fld.closest('.control-group').addClass('error')
    fld.parent().append("<span class='help-inline'>#{ msg }</span>")
  
  removeErrorAt: (fld) ->
    fld.closest('.control-group').removeClass('error')
    @$('.help-inline').remove()
  
  getParams: ->
    params = {}
    params['work_details'] = @detailsFld.val()
    params['duration'] = @duration
    unless @options.edit
      params['date_filed'] = new Date(@dateFiled)
      params['date_of_overtime'] = new Date(@dateOfOT)
    return params

  submitForm: (event) ->
    event.preventDefault()
    @resetDurationFld(event)
    if @validateDuration()
      $.ajax
        url: @$("#overtime-form").attr('action')
        data: { 'overtime': @getParams() }
        dataType: 'json'
        type: if @options.edit then 'PUT' else 'POST'
        beforeSend: (jqXHR, settings) => @disableFormActions()
        success: @onSuccess
        error: @handleFailure

  onSuccess: (data) =>
    @enableFormActions()
    flash_messages = data.flash_messages
    if flash_messages.error is undefined
      $('#overtime-form-modal').modal('hide')
      $('#date-nav-tab li.day.active').trigger('click')
      @showFlash(data.flash_messages)
    else
      $('#flash_messages').html(@flash_messages(flash_messages))
  
  handleError: (entry, response) ->
    if response.status == 500
      $('#overtime-form-modal').modal('hide')
      errors = $.parseJSON(response.responseText).errors
      for attribute, messages of errors
        alert "#{attribute} #{message}" for message in messages

  enableFormActions: ->
    $('.submit').removeAttr('disabled')
    $('.cancel').removeAttr('disabled')
  
  disableFormActions: ->
    $('.submit').attr('disabled', true)
    $('.cancel').attr('disabled', true)
  
