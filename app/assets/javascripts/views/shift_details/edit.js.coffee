class Egems.Views.EditShiftDetail extends Backbone.View

  initialize: ->
    @form  = new Egems.Views.ShiftDetailForm(model: @model)

  render: ->
    $(@el).html(@form.render().el)
    this
