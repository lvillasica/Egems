class Egems.Routers.EmployeeMappings extends Backbone.Router
  routes:
    'employee_mappings': 'index'
  
  index: ->
    @collection = new Egems.Collections.Employees()
    @collection.reset($('#data-container').data('employees'))
    view = new Egems.Views.EmployeeMapping(collection: @collection)
    $('#main-container').html(view.render().el)
