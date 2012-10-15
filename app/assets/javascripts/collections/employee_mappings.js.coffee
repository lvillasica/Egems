class Egems.Collections.EmployeeMappings extends Backbone.Collection

  url: '/employee_mappings'
  model: Egems.Models.EmployeeMapping
  
  comparator: (mapping) ->
    mapping.fullName()
