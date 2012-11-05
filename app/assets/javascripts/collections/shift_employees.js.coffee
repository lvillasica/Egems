class Egems.Collections.ShiftScheduleEmployees extends Backbone.Collection

  model: Egems.Models.ShiftScheduleEmployee
  initialize: (options) ->
    options || (options = {})
    this.shiftId = options.shiftId

  url: ->
    return '/hr/shifts/' + this.shiftId + '/employees'
