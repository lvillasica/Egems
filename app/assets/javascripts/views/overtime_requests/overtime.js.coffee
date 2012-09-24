class Egems.Views.OvertimeRequest extends Backbone.View

  template: JST['overtime_requests/overtime']
  details: JST['overtimes/details']
  tagName: 'tr'

  events: ->
    "click .overtime-details" : "viewDetails"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Timesheets)

  render: ->
    $(@el).html(@template(
      overtime: @model
      mixins: @mixins
    ))
    this

  viewDetails: (event) =>
    event.preventDefault()
    $('#main-container').append('<div id="view-details-modal" class="modal hide fade" />')
    $('#view-details-modal').append(@details(overtime: @model, mixins: @mixins))
    $('#view-details-header').wrap('<div class="modal-header" />')
    $('#view-details-header').prepend('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>')
    $('.modal-header').next('hr').remove()
    $('#view-details-body').addClass('modal-body')
    $('#view-details-modal').modal('show')
    $('#view-details-modal').on 'hidden', ->
      $(this).remove()
