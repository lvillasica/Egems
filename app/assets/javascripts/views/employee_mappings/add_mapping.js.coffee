class Egems.Views.AddMapping extends Backbone.View
  
  template: JST['employee_mappings/add_mapping']

  events:
    "click #employee-mapping-form-actions .submit" : "triggerSubmit"

  initialize: ->
    _.extend(this, Egems.Mixins.EmployeeMappings)
    @selectedEmployee = @options.selectedEmployee
    @all_mapped = @options.all_mapped
    @type = @options.type
    @mappedEmployees = @options.mappedEmployees
    @mappableEmployeeView = @options.mappableEmployeeView
    @form = new Egems.Views.EmployeeMappingForm
      selectedEmployee: @selectedEmployee
      all_mapped: @all_mapped
      type: @type
      mappedEmployees: @mappedEmployees
      mappableEmployeeView: @mappableEmployeeView

  render: ->
    $(@el).html(@template(type: @type))
    @$("#employee-mapping-form-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#employee-mapping-form").attr("action", "/employee_mappings").submit()
