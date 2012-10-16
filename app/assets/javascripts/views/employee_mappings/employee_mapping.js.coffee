class Egems.Views.EmployeeMapping extends Backbone.View

  template: JST['employee_mappings/employee_mapping']
  id: 'employee-mapping-container'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
  
  render: ->
    $(@el).html(@template(employees: @collection))
    @collection.each(@appendEmployee)
    @initSearchEvents()
    this
  
  initSearchEvents: ->
    @searchFld = @$('#employee-search')
    @searchFld.keyup @searchEmployee
  
  appendEmployee: (employee) =>
    view = new Egems.Views.MappableEmployee(model: employee)
    @$('#employees-lst').append(view.render().el)
  
  searchEmployee: (event) =>
    res = _.filter @collection.models, (employee) =>
      return employee if @has_match(employee.fullName(), @searchFld.val())
    @$('#employees-lst').empty()
    _.each(res, @appendEmployee)
  
  has_match: (str1, str2) ->
    str1.toLowerCase().indexOf(str2.toLowerCase()) != -1
