class Egems.Views.NewShiftDetail extends Backbone.View

  initialize: ->
    @day   = this.options.dayNum
    @model = new Egems.Models.ShiftDetail({ 'day_of_week' : @day })
    @form  = new Egems.Views.ShiftDetailForm(model: @model)

  render: ->
    $(@el).html(@form.render().el)
    this
