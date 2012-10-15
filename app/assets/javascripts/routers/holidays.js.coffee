class Egems.Routers.Holidays extends Backbone.Router

  routes:
    'hr/holidays' : 'index'

  index: ->
    @collection = new Egems.Collections.Holidays()
    @collection.fetch
      async: false

    indexView = new Egems.Views.HolidaysIndex(collection: @collection)
    $('#main-container').html(indexView.render().el)
