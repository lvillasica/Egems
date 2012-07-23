class Egems.Routers.LeaveDetails extends Backbone.Router
  routes:
    'leave_details/new': 'newLeaveDetail'
  
  newLeaveDetail: ->
    @model = new Egems.Models.LeaveDetail($('#data-container').data('leave-detail'))
    newLeaveDetail = new Egems.Views.NewLeaveDetail(model: @model)
    $('#main-container').html(newLeaveDetail.render().el)
