class Egems.Models.ShiftDetail extends Backbone.Model

  amStart: ->
    @get 'local_am_start'

  amDuration: ->
    @get 'am_time_duration'

  amAllowance: ->
    @get 'am_time_allowance'

  day: ->
    days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    dayNum = @get('day_of_week')
    days[parseInt(dayNum)]

  dayNum: ->
    @get 'day_of_week'

  pmStart: ->
    @get 'local_pm_start'

  pmDuration: ->
    @get 'pm_time_duration'

  pmAllowance: ->
    @get 'pm_time_allowance'

  shift: ->
    @get 'shift_schedule_id'
