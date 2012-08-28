class Egems.Routers.Leaves extends Backbone.Router
  routes:
    'leaves': 'index'
  
  initializeCollection: ->
    @collection = new Egems.Collections.Leaves()
    data = $('#data-container').data('leaves')
    if data is not undefined
      @collection.reset(data)
    else
      @collection.fetch
        async: false
        success: (collection, response) =>
          @collection.reset(response.leaves)
  
  index: ->
    @initializeCollection()
    index = new Egems.Views.LeavesIndex(collection: @collection)
    leaves_accordion = new Egems.Views.LeavesAccordion(collection: @collection)
    $('#main-container').html(index.render().el)
    $('#leave_details_container').html(leaves_accordion.render().el)
