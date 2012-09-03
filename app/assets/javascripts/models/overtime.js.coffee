class Egems.Models.Overtime extends Backbone.Model

  dateFiled: ->
    @get 'date_filed'

  dateOfOvertime: ->
    @get 'date_of_overtime'

  workDetails: ->
    @get 'work_details'

  duration: ->
    @get 'duration'

  durationApproved: ->
    @get 'duration_approved'

  status: ->
    @get 'status'

  responders: ->
    @get 'responders'
