class Egems.Routers.Timesheets extends Backbone.Router
  routes:
    '': 'index'

  initialize: ->
    @collection = new Egems.Collections.Timesheets()
    @collection.fetch()

  index: ->
    index = new Egems.Views.TimesheetsIndex(collection: @collection)
    $('#main-container').html(index.render().el)
    index.updateDateTabs()
