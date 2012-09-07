class Egems.Views.TimesheetRequest extends Backbone.View

  template: JST['timesheet_requests/timesheet']
  details: JST['timesheets/details']
  tagName: 'tr'

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Timesheets)

  events: ->
    "click .timesheet-details" : "viewDetails"

  render: ->
    $(@el).html(@template(
      timesheet: @model
      mixins: @mixins
    ))
    @labelManuality()
    this

  labelManuality: ->
    if @model.validity() == 2
      @$('td#time-out').addClass("manual-time")
    else if @model.validity() == 3
      @$('td#time-in').addClass("manual-time")

  viewDetails: (event) =>
    event.preventDefault()
    $('#main-container').append('<div id="view-details-modal" class="modal hide fade" />')
    $('#view-details-modal').append(@details(timesheet: @model, mixins: @mixins))
    $('#view-details-header').wrap('<div class="modal-header" />')
    $('#view-details-header').prepend('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>')
    $('.modal-header').next('hr').remove()
    $('#view-details-body').addClass('modal-body')
    $('#view-details-modal').modal('show')
    $('#view-details-modal').on 'hidden', ->
      $(this).remove()
