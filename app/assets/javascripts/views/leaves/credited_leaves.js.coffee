class Egems.Views.CreditedLeaves extends Backbone.View

  template: JST['leaves/credited_leaves']

  render: ->
    $(@el).html(@template(leaves: @collection))
    @collection.each(@appendLeaveEntry)
    this

  appendLeaveEntry: (leave) =>
    view = new Egems.Views.CreditedLeave(model: leave)
    @$('#credited-leaves-tbl tbody').append(view.render().el)
