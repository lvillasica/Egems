class Egems.Views.TimesheetsIndex extends Backbone.View

  template: JST['timesheets/index']

  events: ->
    "click #time-in-btn" : "timein"
    "click #time-out-btn" : "timeout"

  render: ->
    $(@el).html(@template())
    this

  timein: ->
    event.preventDefault()
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: '/timein'
      success: (data) =>
        if data.invalid_timesheets != null
          view = new Egems.Views.ManualTimeout(collection: data.invalid_timesheets)
          $('#main-container').html(view.render().el)
        else
          @collection.reset(data.employee_timesheets_active)
          navs = new Egems.Views.DateNavs()
          navs.activateDateTab()

  timeout: ->
    event.preventDefault()
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: '/timeout'
      success: (data) =>
        if data.invalid_timesheets != null
          view = new Egems.Views.ManualTimein(collection: data.invalid_timesheets)
          $('#main-container').html(view.render().el)
        else
          @collection.reset(data.employee_timesheets_active)
          navs = new Egems.Views.DateNavs()
          navs.activateDateTab()

  manualTimeout: ->
    alert "manual timeout"
