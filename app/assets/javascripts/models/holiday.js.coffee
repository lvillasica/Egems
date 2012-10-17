class Egems.Models.Holiday extends Backbone.Model

  branches: ->
    @get 'branches'

  date: ->
    @get 'date'

  description: ->
    @get 'description'

  getId: ->
    @get 'id'

  isCancelable: ->
    @get 'cancelable'

  isEditable: ->
    @get 'editable'

  name: ->
    @get 'name'

  type: ->
    @get 'holiday_type'
