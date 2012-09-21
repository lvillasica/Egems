class Egems.Views.DateNavs extends Backbone.View
  template: JST['timesheets/date_navs']
  id: "date-container"

  events:
    'click #date-nav-tab li.day': 'gotoDate'
    'click #date-nav-tab li.week': 'gotoWeek'
    'click #week-tab-trigger': 'gotoWeek'

  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets)

  render: ->
    $(@el).html(@template(weekPickerVal: @weekPickerVal(Date.today().clone())))
    this

  activateDateTab: (current = Date.today()) ->
    cwday = I18n.strftime(current, '%a')
    $("#date-nav-tab li").removeClass('active')
    $("#date-nav-tab li.#{cwday.toLowerCase()}").addClass('active')

  activateWeekTab: ->
    $("#date-nav-tab li").removeClass('active')
    $("#date-nav-tab li.week").addClass('active')

  gotoDate: (event) ->
    event.preventDefault()
    activeTime = new Date($('#week-picker').val().split(" ")[0])
    time = @getDayOfWeek(activeTime.clone())[$(event.target).text().toLowerCase()]
    path = "/timesheets/#{time}"
    @collection.fetch
      type: 'POST'
      dataType: 'json'
      url: path
      success: (col, data) =>
        @activateDateTab(new Date(time))

  gotoWeek: (event) ->
    event.preventDefault()
    activeTime = new Date($('#week-picker').val().split(" ")[0])
    path = "/timesheets/#{activeTime}/week"
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: path
      success: (data) =>
        view = new Egems.Views.TimeEntriesWeekly(collection: data.employee_timesheets_active)
        $('#time-entries-container').html(view.render().el)
        @activateWeekTab()
