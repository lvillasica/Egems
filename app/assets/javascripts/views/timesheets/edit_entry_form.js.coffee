class Egems.Views.EditEntryForm extends Backbone.View
  template: JST['timesheets/edit_entry_form']
  tagName: 'form'
  className: 'form-inline'
  
  events:
    'click .submit-trigger': 'triggerSubmit'
    'submit': 'submitForm'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @action = ''  # 'timein' or 'timeout'
    @time = null
  
  render: ->
    $(@el).html(@template(
      model: @model
      action: @action
      time: @time
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    @initActionTooltip()
    @disableDateField() if @action is 'timein'
    this
  
  initActionTooltip: ->
    $(@el).find('.submit-trigger').tooltip(title: 'Done', placement: 'right')
  
  disableDateField: ->
    if @model is @model.collection.first()
      @$("input[name='#{ @action }[date]']").attr('disabled', true)
  
  setAction: (action) ->
    @action = action
    this
  
  setTime: (time) ->
    @time = time
    this
  
  triggerSubmit: (event) ->
    event.preventDefault()
    $(@el).attr('action', "/timesheets/edit_manual_entry").submit()
    
  getAttributes: ->
    attrs = {}
    date = if @action is 'timein' and @model is @model.collection.first()
      @format_date @model.date()
    else
      @$("input[name='#{ @action }[date]']").val()
    attrs["id"] = @model.id
    attrs["#{ @action }[hour]"] = @$("input[name='#{ @action }[hour]']").val()
    attrs["#{ @action }[min]"] = @$("input[name='#{ @action }[min]']").val()
    attrs["#{ @action }[meridian]"] = @$("select[name='#{ @action }[meridian]']").val()
    attrs["#{ @action }[date]"] = date
    return attrs
  
  resetModel: (data) ->
    type = if @action is 'timein' then 'time_in' else 'time_out'
    time_entry = data.time_entry
    attrs = {}
    attrs["#{ type }"] = time_entry[type]
    attrs["remarks "] = time_entry.remarks
    attrs["duration"] = time_entry.duration
    attrs["minute_late"] = time_entry.minutes_late
    attrs["minutes_undertime"] = time_entry.minutes_undertime
    attrs["minutes_excess"] = time_entry.minutes_excess
    @model.set(attrs)
  
  submitForm: (event) ->
    event.preventDefault()
    $.ajax
      url: $(event.target).attr('action')
      data: @getAttributes()
      dataType: 'json'
      type: 'PUT'
      success: (data) =>
        flash_messages = data.flash_messages
        $('.alert, .tooltip').remove()
        $(event.target).parent().removeClass('error')
        if flash_messages.error is undefined
          type = if @action is 'timein' then 'time_in' else 'time_out'
          @resetModel(data)
          .trigger('change')
          $(event.target).parent().html("#{ @format_long_time data.time_entry[type] }")
          if flash_messages.info
            $(@flash_messages(flash_messages)).insertBefore('#time-entries')
          @model.trigger('highlight')
        else
          $(@flash_messages(flash_messages)).insertBefore('#time-entries')
          $(event.target).parent().addClass('error')

