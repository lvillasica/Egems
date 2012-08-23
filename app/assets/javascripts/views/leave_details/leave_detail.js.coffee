class Egems.Views.LeaveDetail extends Backbone.View
  template: JST['leave_details/leave_detail']
  tagName: 'tr'
  
  events:
    'click a.edit': 'editLeave'
    'click a.cancel': 'cancelLeave'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Leaves)
    @model.on('change', @render, this)
    @model.on('highlight', @highlightRow, this)
    @leaves = @options.leaves
  
  render: ->
    $(@el).html(@template(
      leave_detail: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.LeaveDetails)
    ))
    @initActionsTooltip()
    this
  
  initActionsTooltip: ->
    @$('.edit').tooltip(title: "Edit")
    @$('.cancel').tooltip(title: "Cancel")
  
  highlightRow: ->
    rowpos = $(@el).position().top - ($(window).height() / 2)
    $('html').animate({scrollTop: rowpos}, 'slow')
    $(@el).effect("highlight", {}, 3000)

  
  editLeave: (event) ->
    event.preventDefault()
    $('#main-container').append('<div id="apply-leave-modal" class="modal hide fade" />')
    $.ajax
      url: event.currentTarget.pathname
      dataType: 'json'
      success: (data) =>
        leave = new Egems.Views.LeavesIndex()
        if data is null
          alert "You cannot edit this leave."
        else if data.leave_detail == undefined or data.leave_detail == null
          leave.showError(data.flash_messages)
        else
          leave.showLeaveForm(data, Egems.Views.EditLeaveDetail, @model, @leaves)
  
  cancelLeave: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      $.ajax
        url: event.currentTarget.pathname
        dataType: 'json'
        type: 'POST'
        success: (data) =>
          @model.set status: data.leave_detail.status
          @model.trigger 'highlight'
          @updateNotif(data.total_pending)
          leave = @leaves.get(@model.leaveId())
          leave.set
            total_pending: data.leave_detail.leave_total_pending
            remaining_balance: data.leave_detail.leave_remaining_balance

