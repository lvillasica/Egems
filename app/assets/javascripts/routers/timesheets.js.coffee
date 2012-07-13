class Egems.Routers.Timesheets extends Backbone.Router
  routes:
    '': 'index'

  initialize: ->
    @collection = new Egems.Collections.Timesheets()
    @collection.fetch()

  index: ->
    index = new Egems.Views.TimesheetsIndex(collection: @collection)
    navs = new Egems.Views.DateNavs(collection: @collection)
    time_entries = new Egems.Views.TimeEntries(collection: @collection)
    $('#main-container').html(index.render().el)
    $('#date-nav-container').html(navs.render().el)
    $('#time-entries-container').html(time_entries.render().el)
    navs.trigger('rendered')
