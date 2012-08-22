class Egems.Collections.LeaveRequests extends Backbone.Collection

  url: '/leave_details/requests'
  model: Egems.Models.LeaveDetail

  parse: (response, xhr) ->
    this.approved = response.approved
    this.rejected = response.rejected
    return response.pending
