class Egems.Routers.Overtimes extends Backbone.Router
  routes:
    'overtimes': 'index'

  initializeCollection: ->
    @collection = new Egems.Collections.Overtimes()
    data = $('#data-container').data('overtimes')
    if data is not undefined
      @collection.reset(data)
    else
      @collection.fetch
        async: false
        success: (collection, response) =>
          @collection.reset(response.overtimes)

  index: ->
    @initializeCollection()
    index = new Egems.Views.OvertimesIndex(collection: @collection)
    $('#main-container').html(index.render().el)
