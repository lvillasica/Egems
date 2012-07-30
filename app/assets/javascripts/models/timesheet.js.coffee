class Egems.Models.Timesheet extends Backbone.Model

  date: ->
    @get 'date'

  remarks: ->
    @get 'remarks'

  timeIn: ->
    @get 'time_in'

  timeOut: ->
    @get 'time_out'
