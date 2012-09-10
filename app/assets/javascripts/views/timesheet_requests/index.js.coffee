class Egems.Views.TimesheetRequestsIndex extends Backbone.View

  template: JST['timesheet_requests/index']
  id: 'timesheets-for-approval'

  events: ->
    "click #toggle-boxes" : "toggleCheckedBoxes"
    "click #timesheets-approval-form .approve" : "approveCheckedBoxes"

  initialize: ->
    @collection.on('reset', @render, this)
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Timesheets)

  render: ->
    $(@el).html(@template(timesheets: @collection))
    @collection.each(@appendTimesheet)
    this

  appendTimesheet: (timesheet) =>
    row = new Egems.Views.TimesheetRequest(model: timesheet)
    @$('#timesheet-requests-tbl tbody').append(row.render().el)

  toggleCheckedBoxes: (event) ->
    event.preventDefault()
    className = $('#toggle-boxes')[0].className
    switch className
      when "icon-ok"
        $(event.target).removeClass('icon-ok').addClass('icon-remove')
        $("#timesheets-approval-form table tr td input[type='checkbox']:not(:disabled)").attr('checked', true)
      when "icon-remove"
        $(event.target).removeClass('icon-remove').addClass('icon-ok')
        $("#timesheets-approval-form table tr td input[type='checkbox']:not(:disabled)").attr('checked', false)

  approveCheckedBoxes: (event) ->
    event.preventDefault()
    ids = @getCheckedIds()

    if ids.length > 0
      $.ajax
        url: '/timesheets/approve'
        dataType: 'JSON'
        type: 'POST'
        data: { approved_ids: ids }
        success: (data) =>
          @collection.reset(data.pending)
          if data.errors != undefined
            @showErrors(data.errors)
          else
            @showSuccessMsg(data.success)
    else
      @noCheckedBox()

  getCheckedIds: ->
    _.map $("#timesheets-approval-form input[type='checkbox']:checked"), (box) ->
      $(box).val()

  noCheckedBox: ->
    $('#flash_messages').html @mixins.flash_messages
      error: 'No selected timesheet request.'

  showSuccessMsg: (msg) ->
    $("#flash_messages").html @mixins.flash_messages(msg)
