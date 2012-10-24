class Egems.Models.Employee extends Backbone.Model

  fullName: ->
    @get 'full_name'
  
  dateHired: ->
    @get 'date_hired'
  
  dateRegularized: ->
    @get 'date_regularized'
