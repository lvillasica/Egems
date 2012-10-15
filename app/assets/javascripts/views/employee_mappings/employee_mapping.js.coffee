class Egems.Views.EmployeeMapping extends Backbone.View

  template: JST['employee_mappings/employee_mapping']
  id: 'employee-mapping-container'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
  
  render: ->
    $(@el).html(@template(employees: @collection))
    @collection.each(@appendEmployee)
    this
  
  appendEmployee: (employee) =>
    view = new Egems.Views.MappableEmployee(model: employee)
    @$('#employees-lst').append(view.render().el)
