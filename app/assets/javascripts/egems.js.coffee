window.Egems =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Mixins: {}
  init: ->
    new Egems.Routers.Timesheets()
    new Egems.Routers.TimesheetRequests()
    new Egems.Routers.Leaves()
    new Egems.Routers.LeaveDetails()
    new Egems.Routers.LeaveRequests()
    new Egems.Routers.Overtimes()
    new Egems.Routers.OvertimeRequests()
    new Egems.Routers.Holidays()
    new Egems.Routers.EmployeeMappings()
    new Egems.Routers.ShiftSchedules()
    Backbone.history.start(pushState: true)

$(document).ready ->
  Egems.init() unless $('#sessions-form-container').length is 1
  $('#loading-indicator')
    .ajaxStart (event) ->
      $(this).modal(backdrop: 'static', 'show')
    .ajaxStop (event) ->
      $(this).modal('hide')
