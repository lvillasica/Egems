class Egems.Views.EditMapping extends Backbone.View

  template: JST['employee_mappings/edit_mapping']

  events:
    "click #employee-mapping-form-actions .submit" : "triggerSubmit"

  initialize: ->
    _.extend(this, Egems.Mixins.EmployeeMappings)
    @selectedEmployee = @options.selectedEmployee
    @type = @options.type
    @form = new Egems.Views.EmployeeMappingForm
      model: @model
      selectedEmployee: @selectedEmployee
      type: @type
      edit: true

  render: ->
    $(@el).html(@template(type: @type))
    @$("#employee-mapping-form-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#employee-mapping-form")
    .attr("action", "/employee_mappings/#{ @model.id }")
    .submit()
