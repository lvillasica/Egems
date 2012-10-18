class Egems.Views.ShiftSchedulesIndex extends Backbone.View

  template: JST['shift_schedules/index']

  initialize: ->
    @collection.on('add', @appendShift, this)

  render: ->
    $(@el).html(@template(shifts: @collection))
    this

  appendShift: (shift) ->
    nodata = $("#shifts-tbl tbody tr.nodata")
    if nodata.length > 0
      nodata.remove()

    rowId = shift.getId()
    @shiftView = """
                 <tr id='shift_#{ rowId }'>
                   <th colspan='7'>#{ shift.name() }</th>
                 </tr>
                 """

    $("#shifts-tbl tbody").append(@shiftView)
    $('#shift_' + rowId).click @showDetails
    @putDetails(shift)

  putDetails: (shift) ->
    @details = new Egems.Collections.ShiftDetails({shiftId: shift.getId()})
    @details.fetch
      add: true
    @details.on('add', @appendDetails, this)

  appendDetails: (detail) ->
    detailView = new Egems.Views.ShiftDetail(model: detail)
    shiftView = $('#shifts-tbl tbody tr#shift_' + detail.shift())
    $(detailView.render().el).insertAfter(shiftView).css('display', 'none')

  showDetails: (event) ->
    shiftId = $(event.target).parents("tr:first").attr('id')
    $('.' + shiftId + '_details').toggle()
