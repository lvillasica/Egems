class Egems.Models.Overtime extends Backbone.Model

  dateFiled: ->
    @get 'date_filed'

  dateOfOvertime: ->
    @get 'date_of_overtime'

  details: ->
    @get 'work_details'

  duration: ->
    @get 'duration'

  durationApproved: ->
    @get 'duration_approved'

  employeeName: ->
    @get 'employee_name'

  getId: ->
    @get 'id'

  status: ->
    @get 'status'

  responders: ->
    @get 'responders'
  
  maxDuration: ->
    @get 'max_duration'
  
  responseDate: ->
    @get 'response_date'
