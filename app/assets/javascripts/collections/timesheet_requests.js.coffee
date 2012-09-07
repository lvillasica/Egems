class Egems.Collections.TimesheetRequests extends Backbone.Collection

  url: '/timesheets/requests'
  model: Egems.Models.Timesheet

  parse: (response, xhr) ->
    return response.pending
