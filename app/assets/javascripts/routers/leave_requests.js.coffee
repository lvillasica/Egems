class Egems.Routers.LeaveRequests extends Backbone.Router

  routes:
    'leave_details/requests' : 'index'

  index: ->
    @collection = new Egems.Collections.LeaveRequests()
    @collection.fetch
      async: false

    view = new Egems.Views.LeaveRequestsIndex(collection: @collection)
    $('#main-container').html(view.render().el)
