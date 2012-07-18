class Egems.Models.LeaveDetail extends Backbone.Model

  leaveDate: ->
    @get 'leave_date'
  
  leaveType: ->
    @get 'leave_type'
  
  details: ->
    @get 'details'
  
  leaveUnit: ->
    @get 'leave_unit'
  
  period: ->
    @get 'period'
  
  status: ->
    @get 'status'
