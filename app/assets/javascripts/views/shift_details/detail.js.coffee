class Egems.Views.ShiftDetail extends Backbone.View

  template: JST['shift_details/detail']
  tagName: 'tr'

  className: =>
    'shift_' + @model.shift() + '_details'

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@template(detail: @model, mixins: @mixins))
    this
