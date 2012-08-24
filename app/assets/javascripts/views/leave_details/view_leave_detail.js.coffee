class Egems.Views.ViewLeaveDetail extends Backbone.View

  template: JST['leave_details/view_leave_detail']
  id: "view-details-container"

  render: ->
    $(@el).html(@template(
      leave_detail: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initInactiveForm()
    this

  initInactiveForm: ->
    @$("#inactive-form.form-horizontal :input").attr("disabled", true)
