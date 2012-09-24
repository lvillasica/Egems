class Egems.Collections.OvertimeRequests extends Backbone.Collection

  url: '/timesheets/overtimes/requests'
  model: Egems.Models.Overtime

  parse: (response, xhr) ->
    return response.pending
