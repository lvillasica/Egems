class Egems.Routers.LeaveDetails extends Backbone.Router
  routes:
    'leave_details/new': 'newLeaveDetail'
  
  newLeaveDetail: ->
    alert "New Leave Detail page"
