class Egems.Views.OvertimeRequest extends Backbone.View

  template: JST['overtime_requests/overtime']
  details: JST['overtimes/details']
  tagName: 'tr'

  events: ->
    "click .overtime-details" : "viewDetails"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
    @duration = @model.duration()

  render: ->
    $(@el).html(@template(
      overtime: @model
      mixins: @mixins
    ))
    @initDuration()
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


  initDuration: ->
    @durationFld = @$('input[name="duration-approved"]')
    @durationFld.val(@format_in_hours @duration)
    @durationFld.click @fillDuration

  fillDuration: (event) =>
    event.preventDefault()
    container = @durationFld.parent()
    @wrapper  = $("<div id='hhmmcont'/>")
    @hrsFld   = $("<input type='text' size='2' maxlength='2' class='time hrs'/>")
    @minsFld  = $("<input type='text' size='2' maxlength='2' class='time mins'/>")
    resetBtn  = $("<a class='hhmmok' href=''><i class='icon-ok'></i></a>")

    @durationFld.hide()
    container.append(@wrapper).addClass("hhmmtd")

    @wrapper.append(@hrsFld).append("hr(s) ")
            .append(@minsFld).append("min(s) ")
            .append(resetBtn)

    @hrsFld.val(@getHoursFromMins @model.duration())
    @minsFld.val(@getMinsFromMins @model.duration())

    resetBtn.click @resetDuration
    @minsFld.change @updateDuration
    @hrsFld.change @updateDuration

  updateDuration: (event) =>
    event.preventDefault()
    hrs  = @hrsFld.val()
    mins = @minsFld.val()
    @model.set({ duration: @hrsToMins(hrs, mins) })

  resetDuration: (event) =>
    event.preventDefault()
    container = @durationFld.parents('td')
    container.removeClass('hhmmtd')
    @wrapper.remove()
    @updateDuration
    @durationFld.val(@format_in_hours @model.duration())
    container.find("input[name='duration-approved']").css('display', 'inline-block')
