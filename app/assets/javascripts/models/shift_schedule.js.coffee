class Egems.Models.ShiftSchedule extends Backbone.Model

  createdOn: ->
    @get 'created_on'

  description: ->
    @get 'description'

  differentialRate: ->
    @get 'differential_rate'

  getId: ->
    @get 'id'

  name: ->
    @get 'name'
