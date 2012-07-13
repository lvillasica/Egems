class Egems.Views.TimesheetsIndex extends Backbone.View
  
  template: JST['timesheets/index']
  
  render: ->
    $(@el).html(@template())
    this
