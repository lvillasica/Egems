class Egems.Collections.ShiftDetails extends Backbone.Collection

  model: Egems.Models.ShiftDetail
  initialize: (options) ->
    options || (options = {})
    this.shiftId = options.shiftId

  url: ->
    return '/hr/shifts/' + this.shiftId + '/details'
