class Egems.Views.LeaveDetail extends Backbone.View
  template: JST['leave_details/leave_detail']
  tagName: 'tr'
  
  events:
    'click a.edit': 'editLeave'
    'click a.cancel': 'cancelLeave'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      leave_detail: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initActionsTooltip()
    this
  
  initActionsTooltip: ->
    @$('.edit').tooltip(title: "Edit")
    @$('.cancel').tooltip(title: "Cancel")
  
  editLeave: (event) ->
    event.preventDefault()
    $('#main-container').append('<div id="apply-leave-modal" class="modal hide fade" />')
    $.ajax
      url: event.currentTarget.pathname
      dataType: 'json'
      success: (data) =>
        leave = new Egems.Views.LeavesIndex()
        if data.leave_detail == undefined or data.leave_detail == null
          leave.showError(data.flash_messages)
        else
          leave.showLeaveForm(data, Egems.Views.EditLeaveDetail)
  
  cancelLeave: (event) ->
    event.preventDefault()
    alert event.currentTarget.pathname if confirm "Are you sure?"
