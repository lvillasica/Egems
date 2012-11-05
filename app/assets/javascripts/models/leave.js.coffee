class Egems.Models.Leave extends Backbone.Model

  leaveType: ->
    @get('leave_type')
  
  leavesAllocated: ->
    @get 'leaves_allocated'
  
  leavesConsumed: ->
    @get 'leaves_consumed'
  
  totalPending: ->
    @get 'total_pending'
  
  remainingBalance: ->
    @get 'remaining_balance'
  
  dateFrom: ->
    @get 'date_from'
  
  dateTo: ->
    @get 'date_to'
  
  validity: ->
    format_date = Egems.Mixins.Defaults.format_date
    if @leaveType() != "Absent Without Pay"
      return "#{ format_date @dateFrom() } to #{ format_date @dateTo() }"
    else
      return "Not Applicable"
  
  employeeName: ->
    @get 'employee_name'
  
  employeeId: ->
    @get 'employee_id'
  
  wDocs: ->
    @get 'w_docs'
