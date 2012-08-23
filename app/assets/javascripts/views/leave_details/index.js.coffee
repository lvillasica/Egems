class Egems.Views.LeaveDetailsIndex extends Backbone.View

  template: JST['leave_details/index']
  
  initialize: ->
    @collection.on('reset', @render, this)
    @collection.on('add', @render, this)
    @leaves = @options.leaves
  
  render: ->
    $(@el).html(@template(leave_details: @collection))
    @collection.each(@appendLeaveDetail)
    this
  
  appendLeaveDetail: (leave_detail) =>
    view = new Egems.Views.LeaveDetail(model: leave_detail, leaves: @leaves)
    @$('#leave_details_tbl tbody').append(view.render().el)
