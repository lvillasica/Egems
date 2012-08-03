class Egems.Views.TimeEntriesWeekly extends Backbone.View
  template: JST['timesheets/time_entries_weekly']
  id: "weekly-entries"

  events: ->
    "click td.remarks.leavable" : "linkToLeaveFile"

  render: ->
    $(@el).html(@template(
      timeEntriesPerDay: @collection
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    ))
    this

  linkToLeaveFile: (event) ->
    event.preventDefault()
    date = $(event.target).parent().find("td#tdate").text()
    data = 'date=' + date.trim()
    $('#main-container').append('<div id="apply-leave-modal" class="modal hide fade" />')
    $.ajax
      url: 'timesheets/leaves/new'
      dataType: 'json'
      data: data
      success: (data) ->
        leave = new Egems.Views.LeavesIndex()
        leave.showLeaveForm(data)

  notFileable: (cell) ->
    cell.css({cursor: 'default', color: 'black'})
