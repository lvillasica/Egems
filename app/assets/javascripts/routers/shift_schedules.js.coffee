class Egems.Routers.ShiftSchedules extends Backbone.Router

  routes:
    'hr/shifts' : 'index'

  index: ->
    @collection = new Egems.Collections.ShiftSchedules()
    @collection.fetch
      add: true

    index = new Egems.Views.ShiftSchedulesIndex(collection: @collection)
    $("#main-container").html(index.render().el)
