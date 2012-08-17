class Egems.Models.LeaveDetail extends Backbone.Model

  getId: ->
    @get 'id'

  leaveDate: ->
    @get 'leave_date'
  
  endDate: ->
    @get 'end_date'
  
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
  
  getResponders: ->
    @get 'get_responders'
  
  leaveStartDate: ->
    @get 'leave_start_date'
  
  leaveEndDate: ->
    @get 'leave_end_date'
  
  dayOffs: ->
    @get 'day_offs'
  
  holidays: ->
    @get 'holidays'
  
  employeeLeaves: ->
    @get 'employee_leaves'
  
  periodInWords: ->
    periods = ["Whole Day", "AM", "PM", "Range"]
    periods[@period()]
