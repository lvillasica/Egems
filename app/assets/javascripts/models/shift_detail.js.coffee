class Egems.Models.ShiftDetail extends Backbone.Model

  defaults: ->
    'local_am_start' : new Date().setHours(0,0,0,0)
    'am_time_duration': 0
    'am_time_allowance': 0
    'local_pm_start' : new Date().setHours(0,0,0,0)
    'pm_time_duration': 0
    'pm_time_allowance': 0

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
