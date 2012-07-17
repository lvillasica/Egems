class Egems.Routers.Leaves extends Backbone.Router
  routes:
    'leaves': 'index'
  
  initialize: ->
    @collection = new Egems.Collections.Leaves()
    @collection.reset($('#data-container').data('leaves'))
  
  index: ->
    index = new Egems.Views.LeavesIndex(collection: @collection)
    $('#main-container').html(index.render().el)
