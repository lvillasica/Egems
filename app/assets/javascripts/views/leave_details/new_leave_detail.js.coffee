class Egems.Views.NewLeaveDetail extends Backbone.View

  template: JST['leave_details/new_leave_detail']
  
  render: ->
    $(@el).html(@template())
    form = new Egems.Views.LeaveDetailForm(model: @model)
    @$("#leave_detail_form").html(form.render().el)
    this
  
