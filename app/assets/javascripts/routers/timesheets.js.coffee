class Egems.Routers.Timesheets extends Backbone.Router
  routes:
    '': 'index'

  initialize: ->
    @collection = new Egems.Collections.Timesheets()
    @collection.fetch()
    @collection.on('reset', @checkInvalid, this)

  checkInvalid: ->
    if @collection.invalid_timesheet != null
      index = new Egems.Views.ManualTimeout
        model: @collection.invalid_timesheet
        error: @collection.error
      $('#main-container').html(index.render().el)

  index: ->
    index = new Egems.Views.TimesheetsIndex(collection: @collection)
    $('#main-container').html(index.render().el)
    index.updateDateTabs()
