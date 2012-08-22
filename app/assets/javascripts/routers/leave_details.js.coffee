class Egems.Routers.LeaveDetails extends Backbone.Router
  routes:
    'leave_details/new': 'newLeaveDetail'
    'leave_details/:id/edit': 'editLeaveDetail'
  
  newLeaveDetail: ->
    @model = new Egems.Models.LeaveDetail($('#data-container').data('leave-detail'))
    newLeaveDetail = new Egems.Views.NewLeaveDetail(model: @model)
    $('#main-container').html(newLeaveDetail.render().el)
  
  editLeaveDetail: (id) ->
    if $('#data-container').data('leave-detail') is undefined
      alert "You cannot edit this leave with id ##{id}."
      Backbone.history.navigate('/leaves', true)
    else
      @model = new Egems.Models.LeaveDetail($('#data-container').data('leave-detail'))
      editLeaveDetail = new Egems.Views.EditLeaveDetail(model: @model)
      $('#main-container').html(editLeaveDetail.render().el)
