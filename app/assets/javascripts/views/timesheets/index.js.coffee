class Egems.Views.TimesheetsIndex extends Backbone.View
  
  template: JST['timesheets/index']
  
  initialize: ->
    @collection.on('reset', @render, this)
  
  render: ->
    $(@el).html(@template(
      employee_timesheets_active: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    this
