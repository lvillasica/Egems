class Egems.Models.Timesheet extends Backbone.Model
  
  date: ->
    @get 'date'
  
  timeIn: ->
    @get 'time_in'
  
  timeOut: ->
    @get 'time_out'
