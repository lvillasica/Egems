class Egems.Models.EmployeeMapping extends Backbone.Model

  approverId: ->
    @get 'approver_id'
  
  employeeId: ->
    @get 'employee_id'

  fullName: ->
    @get 'full_name'
  
  approverType: ->
    @get 'approver_type'
  
  approverFrom: ->
    @get 'from'
  
  approverTo: ->
    @get 'to'
