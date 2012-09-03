class Egems.Routers.Overtimes extends Backbone.Router
  routes:
    'overtimes': 'index'
    'overtimes/new': 'newOvertimeEntry'

  initialize: ->
    @collection = new Egems.Collections.Overtimes()
    data = $('#data-container').data('overtime')
    if data is not undefined
      @collection.reset(data)
    else
      @collection.fetch
        async: false
        success: (collection, response) =>
          @collection.reset(response.overtime)

  index: ->
    index = new Egems.Views.OvertimesIndex(collection: @collection)
    $('#main-container').html(index.render().el)

  newOvertimeEntry: ->
    newOvertime =  new Egems.Views.NewOvertimeEntry()
    $('#main-container').html(newOvertime.render().el)
