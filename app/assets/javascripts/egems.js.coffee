window.Egems =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Mixins: {}
  init: ->
    new Egems.Routers.Timesheets()
    new Egems.Routers.Leaves()
    new Egems.Routers.LeaveDetails()
    Backbone.history.start(pushState: true)

$(document).ready ->
  Egems.init() unless $('#sessions-form-container').length is 1
