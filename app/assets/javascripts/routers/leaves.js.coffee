class Egems.Routers.Leaves extends Backbone.Router
  routes:
    'leaves': 'index'
  
  initialize: ->
    @collection = new Egems.Collections.Leaves()
    @collection.reset($('#data-container').data('leaves'))
  
  index: ->
    index = new Egems.Views.LeavesIndex(collection: @collection)
    leaves_accordion = new Egems.Views.LeavesAccordion(collection: @collection)
    $('#main-container').html(index.render().el)
    $('#leave_details_container').html(leaves_accordion.render().el)
