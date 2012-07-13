class Egems.Routers.Timesheets extends Backbone.Router
  routes:
    '': 'index'

  initialize: ->
    @collection = new Egems.Collections.Timesheets()
    @collection.fetch()

  index: ->
    view = new Egems.Views.TimesheetsIndex(collection: @collection)
    navs = new Egems.Views.DateNavs(collection: @collection)
    $('#main-container').html(view.render().el).load ->
      $('#date-nav-container').html(navs.render().el)
    navs.trigger('rendered')
