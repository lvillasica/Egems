class Egems.Views.Holiday extends Backbone.View

  template: JST['holidays/holiday']
  tagName: 'tr'

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Holidays)

  render: ->
    $(@el).html(@template(
      holiday: @model
      mixins: @mixins
    ))
    this
