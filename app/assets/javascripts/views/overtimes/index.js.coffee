class Egems.Views.OvertimesIndex extends Backbone.View

  template: JST['overtimes/index']

  initialize: ->
    @collection.on('reset', @render, this)
    @collection.on('add', @render, this)

  render: ->
    $(@el).html(@template(overtime: @collection))
    @collection.each(@appendOvertime)
    this

  appendOvertime: (overtime) =>
    view = new Egems.Views.OvertimesEntry(model: overtime)
    @$("#overtimes_tbl tbody").append(view.render().el)

