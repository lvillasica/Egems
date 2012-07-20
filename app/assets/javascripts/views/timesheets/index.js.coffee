class Egems.Views.TimesheetsIndex extends Backbone.View

  template: JST['timesheets/index']

  events: ->
    "click #time-in-btn" : "timein"
    "click #time-out-btn" : "timeout"

  initialize: ->
    this.dateNavs = new Egems.Views.DateNavs(collection: @collection)
    this.timeEntries = new Egems.Views.TimeEntries(collection: @collection)

  render: ->
    $(@el).html(@template())
    $(@el).append(this.dateNavs.render().el)
    $(@el).append(this.timeEntries.render().el)
    this

  updateDateTabs: ->
    this.dateNavs.activateDateTab()
    weekPicker()

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
          console.log data
          #@manualTimein(data.invalid_timesheet, data.error)
        else
          @updateEntriesView(data.employee_timesheets_active)

  updateEntriesView: (timesheets) ->
    @collection.reset(timesheets)
    @updateDateTabs()

  manualTimein: (timesheet, error) ->
    view = new Egems.Views.ManualTimein(model: timesheet, error: error)
    $('#main-container').html(view.render().el)

  manualTimeout: (timesheet, error) ->
    view = new Egems.Views.ManualTimeout(model: timesheet, error: error)
    $('#main-container').html(view.render().el)
