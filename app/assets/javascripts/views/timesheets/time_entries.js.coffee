class Egems.Views.TimeEntries extends Backbone.View
  template: JST['timesheets/time_entries']
  id: "time-entries-container"

  events: ->
    "click td.remarks.leavable" : "linkToLeaveFile"
    "click td#overtime_apply" : "overtimeApplication"

  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets, Egems.Mixins.Defaults)
    @collection.on('reset', @render, this)

  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
    @editableEntries = @collection.editableEntries()
    @disapprovedEntries = @collection.disapprovedEntries()
    $('#actions-container').remove()
    if @collection.length > 0
      actions = @getActions()
      @showActionsBtn(actions) if actions.length > 0
    this

  appendTimeEntry: (timeEntry) =>
    view = new Egems.Views.TimeEntry(model: timeEntry)
    @$('#time-entries tbody').append(view.render().el)
  
  getActions: ->
    actions = new Array()
    remarks = @collection.first().remarks()
    fileLeave = @titleRemarks(remarks)
    # push to actions ['actionName', 'actionSelectorID']
    actions.push([fileLeave, 'fileLeave']) unless fileLeave is ""
    actions.push(['File Overtime', 'fileOvertime']) if @overtimeFilable()
    if @overtimeEditable()
      actions.push(['Edit Overtime', 'editOvertime'])
      actions.push(['Cancel Overtime', 'cancelOvertime'])
    actions.push(['Manual Time Entry', 'manualTimeEntry']) if @isAwol(remarks)
    actions.push(['Edit Manual Entries', 'editManual']) if @editableEntries.length > 0
    return actions
  
  overtimeFilable: ->
    minsExcess = parseInt(@collection.sum_minutes('minutes_excess')) or 0
    minsExcess >= 60 and @collection.overtime is null and not @disapprovedEntries.length > 0
  
  overtimeEditable: ->
    if @withOvertime()
      return _.include(['Pending', 'Rejected'], @collection.overtime.status)
  
  withOvertime: ->
    not(@collection.overtime is null or @editableEntries.length > 0)
  
  showActionsBtn: (actions) ->
    container = $('#timesheet-controls')
    container.append('<p id="actions-container" class="dropdown btn-group" style="display:inline-block;" />')
    $('#actions-container').append """
      <a id="actions-btn" href="#" class="btn btn-large dropdown-toggle" data-toggle="dropdown" style="float:right;" />
    """
    $('#actions-btn').html('<i class="icon-cog icon-large"></i> <i class="caret"></i>')
    .tooltip(title: 'Actions', placement: 'right')
    .append('<ul id="actions-lst" class="dropdown-menu" />')
    .dropdown()
    @appendActions(actions)
    @setActionsEvents() # set events
  
  appendActions: (actions) ->
    strActions = ''
    for action in actions
      strActions += "<li><a id='#{action[1]}' href='#'>#{action[0]}</a></li>"
    $('#actions-lst').css('text-align', 'left').html(strActions)
  
  setActionsEvents: ->
    $('#fileLeave').click @linkToLeaveFile
    $('#fileOvertime').click @overtimeApplication
    $('#editOvertime').click @editOvertime
    $('#cancelOvertime').click @cancelOvertime
    $('#manualTimeEntry').click @manualTimeEntryModal
    $('#editManual').click @triggerEditEntries

  linkToLeaveFile: (event) =>
    event.preventDefault()
    if $(event.target).parents("tr").length > 0
      date = $(event.target).parents("tr").find("td#tdate").text()
    else
      date = $("td#tdate").text()
    data = 'date=' + date.trim()
    $('#main-container').append('<div id="apply-leave-modal" class="modal hide fade" />')
    $.ajax
      url: 'timesheets/leaves/new'
      dataType: 'json'
      data: data
      success: (data) ->
        leave = new Egems.Views.LeavesIndex()
        if data.leave_detail == undefined or data.leave_detail == null
          leave.showError(data.flash_messages)
        else
          leave.showLeaveForm(data)

  overtimeApplication: (event) =>
    event.preventDefault()
    $('#main-container').append('<div id="overtime-form-modal" class="modal hide fade" />')
    $.ajax
      url: 'overtimes/new'
      data: @getOvertimeParams()
      dataType: 'json'
      success: (data) =>
        model = new Egems.Models.Overtime(data.overtime)
        view = new Egems.Views.NewOvertimeEntry(model: model)
        view.showOvertimeForm()
  
  getOvertimeParams: ->
    params =
      'overtime[date_filed]': new Date()
      'overtime[date_of_overtime]': new Date(@collection.first().date())
      'overtime[duration]': @collection.sum_minutes('minutes_excess')
  
  editOvertime: (event) =>
    event.preventDefault()
    $('#main-container').append('<div id="overtime-form-modal" class="modal hide fade" />')
    $.ajax
      url: "overtimes/#{ @collection.overtime.id }/edit"
      dataType: 'json'
      success: (data) =>
        if data.error_response
          alert data.error_response
        else
          model = new Egems.Models.Overtime(data.overtime)
          view = new Egems.Views.EditOvertimeEntry(model: model)
          view.showOvertimeForm()
  
  cancelOvertime: (event) =>
    if confirm "Are you sure?"
      $.ajax
        url: "overtimes/#{ @collection.overtime.id }/cancel"
        dataType: 'json'
        type: 'POST'
        success: (data) =>
          if data.error_response
            alert data.error_response
          else
            $('#date-nav-tab li.day.active').trigger('click')
            @showFlash(data.flash_messages)

  manualTimeEntryModal: (event) =>
    event.preventDefault()
    date = $("td#tdate").text().trim()
    $('#main-container').append('<div id="manual-entry-modal" class="modal hide fade" />')
    form = new Egems.Views.ManualEntryForm(collection: @collection, date: date)
    $('#manual-entry-modal').append(form.render().el)
    form.showAsModal()
  
  triggerEditEntries: (event) =>
    event.preventDefault()
    for entry in @collection.editableEntries()
      entry.trigger('editEntry')

