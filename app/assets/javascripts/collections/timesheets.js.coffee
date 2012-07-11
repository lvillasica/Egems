class Egems.Collections.Timesheets extends Backbone.Collection

  url: '/'
  model: Egems.Models.Timesheet
  
  sum_minutes: ->
    sum = 0
    console.log @models
    for timesheet in @models
      sum += parseFloat(timesheet.get('duration'))
    
    return sum
