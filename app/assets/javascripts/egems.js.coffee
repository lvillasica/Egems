window.Egems =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Mixins: {}
  init: ->
    new Egems.Routers.Timesheets()
    Backbone.history.start()

$(document).ready ->
  Egems.init()
