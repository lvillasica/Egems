class Egems.Views.TimeEntries extends Backbone.View
  template: JST['timesheets/time_entries']
  id: "time-entries-container"

  events: ->
    "click td.remarks.leavable" : "linkToLeaveFile"

  initialize: ->
    @collection.on('reset', @render, this)

  render: ->
    $(@el).html(@template())
    @collection.each(@appendTimeEntry)
    this

  appendTimeEntry: (timeEntry) =>
    view = new Egems.Views.TimeEntry(model: timeEntry)
    @$('#time-entries tbody').append(view.render().el)

  linkToLeaveFile: (event) ->
    event.preventDefault()
    date = $(event.target).parents("tr").find("td#tdate").text()
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
