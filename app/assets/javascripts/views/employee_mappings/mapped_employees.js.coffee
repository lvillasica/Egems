class Egems.Views.MappedEmployees extends Backbone.View

  template: JST['employee_mappings/mapped_employees']
  
  events:
    'click .add': 'addEmployee'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @mappableEmployeeView = @options.mappableEmployeeView
  
  setSelectedEmployee: (employeeModel) ->
    @selectedEmployee = employeeModel
    this
  
  setAllMapped: (allMapped) ->
    @all_mapped = allMapped
  
  render: ->
    $(@el).html(@template(employees: @collection, type: @options.type))
    @collection.sort().each(@appendEmployee)
    this
  
  appendEmployee: (employee) =>
    view = new Egems.Views.MappedEmployee
      model: employee
      selectedEmployee: @selectedEmployee
      type: @getType()
      mappableEmployeeView: @mappableEmployeeView
    @$('#mapped-employees-tbl tbody').append(view.render().el)
  
  addEmployee: (event) =>
    event.preventDefault()
    type = @getType()
    $('#main-container').append('<div id="employee-mapping-form-modal" class="modal hide fade" />')
    view = new Egems.Views.AddMapping
      selectedEmployee: @selectedEmployee
      all_mapped: @all_mapped
      type: type
    view.showEmployeeMappingForm()
  
  getType: ->
    type = ""
    switch @options.type
      when "Supervisors / TL's" then type = "Supervisor/TL"
      when "Project Managers" then type = "Project Manager"
      when "Members" then type = "Member"
    type
