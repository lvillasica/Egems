class Egems.Routers.Timesheets extends Backbone.Router
  routes:
    '': 'index'
    
  initialize: ->
    @collection = new Egems.Collections.Timesheets()
    @collection.reset($('#main-container').data('employee-timesheets-active'))
  
  index: ->
    view = new Egems.Views.TimesheetsIndex(collection: @collection)
    navs = new Egems.Views.DateNavs(collection: @collection)
    $('#date-nav-container').html(navs.render().el)
    $('#main-container').html(view.render().el)
    navs.trigger('rendered')
