class Egems.Views.TimesheetRequestsIndex extends Backbone.View

  template: JST['timesheet_requests/index']
  id: 'timesheets-for-approval'

  events: ->
    "click #toggle-boxes" : "toggleCheckedBoxes"

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
