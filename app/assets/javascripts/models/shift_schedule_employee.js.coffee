class Egems.Models.ShiftScheduleEmployee extends Backbone.Model


  fullName: ->
    @get 'full_name'

  startDate: ->
    @get 'start_date'

  endDate: ->
    @get 'end_date'
