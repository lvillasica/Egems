class Egems.Views.DateNavs extends Backbone.View
  template: JST['timesheets/date_navs']
  
  events:
    'click #date-nav-tab li.day a': 'gotoDate'
    'click #date-nav-tab li.week a': 'gotoWeek'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets)
    @on('rendered', @setActiveDateTab, this)
  
  render: ->
    $(@el).html(@template())
    this
  
  setActiveDateTab: (current = Date.today()) ->
    cwday = I18n.strftime(current, '%a')
    $("#date-nav-tab li").removeClass('active')
    $("#date-nav-tab li.#{cwday.toLowerCase()}").addClass('active')
  
  gotoDate: (event) ->
    event.preventDefault()
    activeTime = Date.today() # TODO: use date-pickers selected date
    time = @getActiveDay(activeTime)[$(event.target).text().toLowerCase()]
    path = "/timesheets/#{time}"
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: path
      success: (data) =>
        @collection.reset(data.employee_timesheets_active)
        @setActiveDateTab(new Date(time))

  gotoWeek: (event) ->
    event.preventDefault()
    alert "go to week!"
