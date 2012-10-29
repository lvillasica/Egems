class Egems.Models.ShiftSchedule extends Backbone.Model

  createdOn: ->
    @get 'created_on'

  description: ->
    @get 'description'

  differentialRate: ->
    @get 'differential_rate'

  getId: ->
    @get 'id'

  isCancelable: ->
    @get 'cancelable'

  isEditable: ->
    @get 'editable'

  name: ->
    @get 'name'
