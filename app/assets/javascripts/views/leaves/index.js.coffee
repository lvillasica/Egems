class Egems.Views.LeavesIndex extends Backbone.View

  template: JST['leaves/index']

  events:
    'click #apply-leave-btn': 'showApplyLeaveModal'

  render: ->
    $(@el).html(@template(leaves: @collection))
    @collection.each(@appendLeaveEntry)
    this

  appendLeaveEntry: (leave) =>
    view = new Egems.Views.Leave(model: leave)
    @$('#leaves_tbl tbody').append(view.render().el)

  showApplyLeaveModal: (event) ->
    event.preventDefault()
    if $("#apply-leave-modal").length == 0
      $('#main-container').append('<div id="apply-leave-modal" class="modal hide fade" />')
    $.ajax
      url: 'leave_details/new'
      dataType: 'json'
      success: (data) =>
        if data.leave_detail == undefined or data.leave_detail == null
          @showError(data.flash_messages)
        else
          @showLeaveForm(data)

  showError: (flashMsgs) ->
    _.extend(this, Egems.Mixins.Leaves)
    $('#apply-leave-modal').append(@noLeaveModal(flashMsgs, isModal: true))
    $('#apply-leave-modal').modal(backdrop: 'static', 'show')
    $('#apply-leave-modal').on 'hidden', ->
      $(this).remove()

  showLeaveForm: (data, view = Egems.Views.NewLeaveDetail, oldData = null, leaves = null, inTimesheet = false) ->
    model = new Egems.Models.LeaveDetail(data.leave_detail)
    leaveDetailForm = new view(model: model, oldData: oldData, leaves: leaves, inTimesheet: inTimesheet)
    $('#apply-leave-modal').append(leaveDetailForm.render().el)
    $('#leave-application-header').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#leave-application-container').addClass('modal-body')
    $('#leave-detail-form-actions').addClass('modal-footer')
    $('#apply-leave-modal').modal(backdrop: 'static', 'show')
    $('#apply-leave-modal').on 'hidden', ->
      $(this).remove()
