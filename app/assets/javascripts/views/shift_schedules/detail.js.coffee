class Egems.Views.ShiftDetail extends Backbone.View

  template: JST['shift_schedules/detail']
  tagName: 'tr'

  className: =>
    'shift_' + @model.shift() + '_details'

  initialize: ->
    @mixins = _.extend(Egems.Mixins.Defaults, this)

  render: ->
    $(@el).html(@template(detail: @model, mixins: @mixins))
    this
