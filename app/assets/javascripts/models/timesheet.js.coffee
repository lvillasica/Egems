class Egems.Models.Timesheet extends Backbone.Model

  date: ->
    @get 'date'

  remarks: ->
    @get 'remarks'

  timeIn: ->
    @get 'time_in'

  timeOut: ->
    @get 'time_out'

  id: ->
    @get 'id'

  getId: ->
    @get 'id'

  duration: ->
    @get 'duration'

  late: ->
    @get 'minutes_late'

  excess: ->
    @get 'minutes_excess'

  undertime:->
    @get 'minutes_undertime'

  validity: ->
    @get 'is_valid'

  employeeName: ->
    @get 'employee_name'
