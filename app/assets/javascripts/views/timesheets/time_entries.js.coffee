class Egems.Views.TimeEntries extends Backbone.View
  template: JST['timesheets/time_entries']
  id: "time-entries-container"

  events: ->
    "click td.remarks.leavable" : "linkToLeaveFile"
    "click td#overtime_apply" : "overtimeApplication"

  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets)
    @collection.on('reset', @render, this)

  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
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
    minsExcess = @collection.sum_minutes('minutes_excess')
    # push to actions ['actionName', 'actionSelectorID']
    actions.push([fileLeave, 'fileLeave']) unless fileLeave is ""
    actions.push(['File Overtime', 'fileOvertime']) if minsExcess > 0
    actions.push(['Manual Time Entry', 'manualTimeEntry']) if @isAwol(remarks)
    return actions
  
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
    $('#manualTimeEntry').click @manualTimeInModal

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
    minutes_excess = $("td#texcess").text() #$(event.target).parents("tr").find("td#texcess").text()
    if $("#apply-overtime-modal").length == 0
      $('#main-container').append('<div id="apply-overtime-modal" class="modal hide fade" />')
    $.ajax
      url: 'overtimes/new'
      data: @model
      dataType: 'json'
      success: (data) ->
        overtime = new Egems.Views.NewOvertimeEntry(model: data)
        overtime.showOvertimeForm(data)

  manualTimeInModal: (event) =>
    event.preventDefault()
    date = $("td#tdate").text().trim()
    $('#main-container').append('<div id="manual-entry-modal" class="modal hide fade" />')
    form = new Egems.Views.ManualEntryForm(collection: @collection, date: date)
    $('#manual-entry-modal').append(form.render().el)
    form.showAsModal()

