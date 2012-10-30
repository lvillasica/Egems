class Egems.Views.LeavesCredited extends Backbone.View

  template: JST['employees/leaves_credited']

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @year = @options.year
    @collection.on('reset', @render, this)

  render: ->
    $(@el).html(@template(employees: @collection))
    @collection.each(@appendEmployee)
    this

  appendEmployee: (employee) =>
    view = new Egems.Views.LeavesCreditedEmployee(model: employee, year: @year)
    @$("#leaves-credited-employees-tbl tbody").append(view.render().el)
