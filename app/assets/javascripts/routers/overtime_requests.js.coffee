class Egems.Routers.OvertimeRequests extends Backbone.Router

  routes:
    'timesheets/overtimes/requests' : 'index'

  index: ->
    @collection = new Egems.Collections.OvertimeRequests()
    @collection.fetch
      async: false

    view = new Egems.Views.OvertimeRequestsIndex(collection: @collection)
    $('#main-container').html(view.render().el)
