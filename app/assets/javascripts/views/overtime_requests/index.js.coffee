class Egems.Views.OvertimeRequestsIndex extends Backbone.View

  template: JST['overtime_requests/index']

  render: ->
    $(@el).html(@template(overtime_requests: @collection))
    @collection.each(@appendRequest)
    this

  appendRequest: (overtime) =>
    view = new Egems.Views.OvertimeRequest(model: overtime)
    @$('#supervisor_pending_overtimes tbody').append(view.render().el)
