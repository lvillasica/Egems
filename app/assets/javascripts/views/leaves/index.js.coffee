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
    $('#main-container').append('<div id="apply-leave-modal" class="modal h‪ide fade" />')
    $('#apply-leave-modal').append('<div class="modal-body" style="max-height:550px"></div>')
    $.ajax
      url: 'leave_details/new'
      dataType: 'json'
      success: (data) ->
        model = new Egems.Models.LeaveDetail(data.leave_detail)
        newLeaveDetail = new Egems.Views.NewLeaveDetail(model: model)
        $('#apply-leave-modal .modal-body').html(newLeaveDetail.render().el)
        $('#apply-leave-modal').modal(backdrop: 'static', 'show')
        $('#apply-leave-modal').on 'hidden', ->
          $(this).remove()
