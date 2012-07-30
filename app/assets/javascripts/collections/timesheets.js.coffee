class Egems.Collections.Timesheets extends Backbone.Collection

  url: '/'
  model: Egems.Models.Timesheet

  parse: (response, xhr) ->
    this.invalid_timesheet = response.invalid_timesheet
    this.error = response.error
    return response.employee_timesheets_active

  sum_minutes: (attribute) ->
    sum = 0
    for timesheet in @models
      sum += parseFloat(timesheet.get(attribute))
    return sum
