class Egems.Collections.Timesheets extends Backbone.Collection

  url: '/'
  model: Egems.Models.Timesheet
  
  sum_minutes: (attribute) ->
    sum = 0
    for timesheet in @models
      sum += parseFloat(timesheet.get(attribute))
    
    return sum
