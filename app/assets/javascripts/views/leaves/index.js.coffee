class Egems.Views.LeavesIndex extends Backbone.View

  template: JST['leaves/index']
  
  render: ->
    $(@el).html(@template(leaves: @collection))
    @collection.each(@appendLeaveEntry)
    this
  
  appendLeaveEntry: (leave) =>
    view = new Egems.Views.Leave(model: leave)
    @$('#leaves_tbl tbody').append(view.render().el)
