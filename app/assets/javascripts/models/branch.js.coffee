class Egems.Models.Branch extends Backbone.Model

  address: ->
    @get 'address'

  code: ->
    @get 'code'

  description: ->
    @get 'description'

  faxNo: ->
    @get 'fax_number'

  getId: ->
    @get 'id'

  name: ->
    @get 'name'

  phoneNo: ->
    @get 'telephone_no'
