class Egems.Models.ShiftSchedule extends Backbone.Model

  createdOn: ->
    @get 'created_on'

  description: ->
    @get 'description'

  differentialRate: ->
    rate = @get 'differential_rate'
    rate * 100

  getId: ->
    @get 'id'

  isCancelable: ->
    @get 'cancelable'

  isEditable: ->
    @get 'editable'

  name: ->
    @get 'name'
