class Egems.Views.LeaveRequestsIndex extends Backbone.View

  template: JST['leave_requests/index']
  list: JST['leave_requests/list']
  id: 'leaves-for-approval'

  events: ->
    "click #toggle-boxes" : "toggleCheckBoxes"
    "click .accordion-toggle" : "toggleAccordion"
    "click #leaves-approval-form .approve" : "approveChecked"
    "click #leaves-approval-form .reject" : "rejectChecked"
    "click #leaves-for-approval tr" : "checkRow"

  initialize: ->
    @collection.on('reset', @render, this)
    @mixins = _.extend(this, Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@template(leaves: @collection))
    @collection.each(@appendLeaveDetail)
    $(@el).append(@list(leaves: @collection.approved, header: 'Approved', mixins: @mixins))
    $(@el).append(@list(leaves: @collection.rejected, header: 'Rejected', mixins: @mixins))
    this

  appendLeaveDetail: (leave) =>
    view = new Egems.Views.LeaveRequest(model: leave)
    @$('#supervisor_pending_leaves tbody').append(view.render().el)

  toggleCheckBoxes: (event) ->
    event.preventDefault()
    className = $('#toggle-boxes')[0].className
    switch className
      when "icon-ok"
        $(event.target).removeClass('icon-ok').addClass('icon-remove')
        $("#leaves-approval-form tbody tr").addClass('selected')
        $("#leaves-approval-form input[type='checkbox']:not(:disabled)").attr('checked', true)
      when "icon-remove"
        $(event.target).removeClass('icon-remove').addClass('icon-ok')
        $("#leaves-approval-form tbody tr").removeClass('selected')
        $("#leaves-approval-form input[type='checkbox']:not(:disabled)").attr('checked', false)

  toggleAccordion: (event) ->
    event.preventDefault()
    $(event.target).parent().next(".accordion-body").slideToggle(300)

  approveChecked: (event) ->
    event.preventDefault()
    ids = @getCheckedIds()

    if ids.length > 0
      $.ajax
        url: '/leave_details/approve'
        dataType: 'JSON'
        type: 'POST'
        data: { approved_ids: ids }
        success: (data) =>
          @listLeaves(data)
          msgContainer = $("#flash_messages")
          msgContainer.empty()
          if data.success != undefined
            @showSuccessMsg(data.success, msgContainer)
            @check_mailing_job_status("leave_request")
          if data.errors != undefined
            @showErrors(data.errors, msgContainer)
    else
      @noCheckedBox()

  rejectChecked: (event) ->
    event.preventDefault()
    ids = @getCheckedIds()

    if ids.length > 0
      $.ajax
        url: '/leave_details/reject'
        dataType: 'JSON'
        type: 'POST'
        data: { rejected_ids: ids }
        success: (data) =>
          @listLeaves(data)
          msgContainer = $("#flash_messages")
          msgContainer.empty()
          if data.success != undefined
            @showSuccessMsg(data.success, msgContainer)
            @check_mailing_job_status("leave_request")
          else
            @showErrors(data.errors, msgContainer)
    else
      @noCheckedBox()

  listLeaves: (data) ->
    @collection.approved = data.approved
    @collection.rejected = data.rejected
    @collection.reset(data.pending)

  noCheckedBox: ->
    $('#flash_messages').html @mixins.flash_messages
      error: 'No selected leave request.'

  showErrors: (errors, container) ->
    container.append(@flash_messages({error: @listMessageHash(errors)}, "multiple"))

  showSuccessMsg: (msg, container) ->
    container.append(@flash_messages(msg, "multiple"))

  getCheckedIds: ->
    _.map $("#leaves-approval-form input[type='checkbox']:checked"), (box) ->
      $(box).val()

  checkRow: (event) ->
    target = event.target
    tr = $(target).parents("tr")

    box = $(':checkbox', tr[0])
    if box.attr('disabled') == undefined
      if target.className != 'icon-comment'
        tr.toggleClass('selected')
      if target.type != 'checkbox' and target.className != 'icon-comment'
        box.prop('checked', !box.attr("checked"))
