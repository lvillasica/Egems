class Egems.Routers.ShiftSchedules extends Backbone.Router

  routes:
    'hr/shifts' : 'index'

  index: ->
    @collection = new Egems.Collections.ShiftSchedules()
    @collection.fetch
      add: true
      success: ->
        @$('#add-shift-btn').removeClass('hidden')

    index = new Egems.Views.ShiftSchedulesIndex(collection: @collection)
    $("#main-container").html(index.render().el)
