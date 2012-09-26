class Egems.Views.OvertimeRequestsIndex extends Backbone.View

  template: JST['overtime_requests/index']

  events: ->
    "click #toggle-boxes" : "toggleCheckBoxes"
    "click #overtimes-approval-form .approve" : "approveChecked"

  initialize: ->
    @collection.on('reset', @render, this)
    @mixins = _.extend(Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@template(overtime_requests: @collection))
    @collection.each(@appendRequest)
    this

  appendRequest: (overtime) =>
    view = new Egems.Views.OvertimeRequest(model: overtime)
    @$('#supervisor_pending_overtimes tbody').append(view.render().el)

  approveChecked: (event) ->
    event.preventDefault()
    ids = @getCheckedIds()

    params = new Object()
    _.each @getDurations(ids), (req) ->
      params[req.getId()] = req.duration()

    if ids.length > 0
      $.ajax
        url: '/timesheets/overtimes/approve'
        dataType: 'JSON'
        type: 'POST'
        data: { approved_ots: params }
        success: (data) =>
          @collection.reset(data.pending)
          if data.errors != undefined
            @showErrors(data.errors)
          else
            @showSuccessMsg(data.success)
    else
      @noCheckedBox()

  getDurations: (ids) ->
    _.filter @collection.models, (m) ->
      _.include ids, m.getId().toString()

  getCheckedIds: ->
    _.map $("#overtimes-approval-form input[type='checkbox']:checked"), (box) ->
      $(box).val()

  noCheckedBox: ->
    $('#flash_messages').html @mixins.flash_messages
      error: 'No selected overtime request.'

  showErrors: (errors) ->
    msg = @mixins.listMessageHash(errors)
    $('#flash_messages').html @mixins.flash_messages({error: msg})

  showSuccessMsg: (msg) ->
    $('#flash_messages').html @mixins.flash_messages(msg)

  toggleCheckBoxes: (event) ->
    event.preventDefault()
    className  = $('#toggle-boxes')[0].className
    checkBoxes = $("#overtimes-approval-form input[type='checkbox']:not(:disabled)")
    switch className
      when "icon-ok"
        $(event.target).removeClass('icon-ok').addClass('icon-remove')
        checkBoxes.attr('checked', true)
      when "icon-remove"
        $(event.target).removeClass('icon-remove').addClass('icon-ok')
        checkBoxes.attr('checked', false)
