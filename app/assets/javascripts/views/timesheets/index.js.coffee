class Egems.Views.TimesheetsIndex extends Backbone.View

  template: JST['timesheets/index']

  events: ->
    "click #time-in-btn" : "timein"
    "click #time-out-btn" : "timeout"

  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets)
    @dateNavs = new Egems.Views.DateNavs(collection: @collection)
    @timeEntries = new Egems.Views.TimeEntries(collection: @collection)

  render: ->
    $(@el).html(@template())
    $(@el).append(@dateNavs.render().el)
    $(@el).append(@timeEntries.render().el)
    this

  updateDateTabs: ->
    this.dateNavs.activateDateTab()
    weekPicker()
    $('#week-picker').val(@weekPickerVal(new Date()))

  timein: (event) ->
    event.preventDefault()
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: '/timein'
      success: (data) =>
        if data.invalid_timesheet != null
          @manualTimeout(data.invalid_timesheet, data.error)
        else
          @updateEntriesView(data.employee_timesheets_active)

  timeout: (event) ->
    event.preventDefault()
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: '/timeout'
      success: (data) =>
        if data.invalid_timesheet != null
          @manualTimein(data)
        else
          @updateEntriesView(data.employee_timesheets_active)

  updateEntriesView: (timesheets) ->
    @collection.reset(timesheets)
    @updateDateTabs()

  manualTimein: (data) ->
    view = new Egems.Views.ManualTimein(
      model: data.invalid_timesheet
      error: data.error
      lastTimesheet: data.lastTimesheet
      shift: data.shift
    )
    $('#main-container').html(view.render().el)

  manualTimeout: (timesheet, error) ->
    view = new Egems.Views.ManualTimeout(model: timesheet, error: error)
    $('#main-container').html(view.render().el)
