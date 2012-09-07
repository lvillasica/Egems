class Egems.Routers.TimesheetRequests extends Backbone.Router

  routes:
    'timesheets/requests' : 'index'

  index: ->
    @collection = new Egems.Collections.TimesheetRequests()
    @collection.fetch
      async: false

    view = new Egems.Views.TimesheetRequestsIndex(collection: @collection)
    $('#main-container').html(view.render().el)
