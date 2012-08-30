class Egems.Models.LeaveDetail extends Backbone.Model

  getId: ->
    @get 'id'

  leaveId: ->
    @get 'employee_truancy_id'

  leaveDate: ->
    @get 'leave_date'

  endDate: ->
    end_date = @get 'end_date'
    if end_date == undefined
      return @get('optional_to_leave_date')
    else
      return end_date

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

  filedBy: ->
    @get 'employee_name'

  dateFiled: ->
    @get 'created_on'

  respondedOn: ->
    @get 'responded_on'

  periodInWords: ->
    periods = ["Whole Day", "AM", "PM", "Range"]
    periods[@period()]

  isCancelable: ->
    @get 'cancelable'

  isApprovable: ->
    @get 'is_approvable'
