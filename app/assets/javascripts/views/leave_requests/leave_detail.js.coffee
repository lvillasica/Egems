class Egems.Views.LeaveRequest extends Backbone.View

  template: JST['leave_requests/leave_detail']
  tagName: 'tr'

  events: ->
    "click .icon-comment" : "viewDetails"

  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @$("tr").filter(':has(:checkbox:checked)')
            .addClass('selected')
            .end()
    this

  viewDetails: (event) ->
    event.preventDefault()
    details = new Egems.Views.ViewLeaveDetail(model: @model)
    $('#main-container').append('<div id="view-details-modal" class="modal hide fade" />')
    $('#view-details-modal').append(details.render().el)
    $('#view-details-header').wrap('<div class="modal-header" />')
    $('#view-details-header').prepend('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>')
    $('.modal-header').next('hr').remove()
    $('#view-details-body').addClass('modal-body')
    $('#view-details-modal').modal('show')
    $('#view-details-modal').on 'hidden', ->
      $(this).remove()
