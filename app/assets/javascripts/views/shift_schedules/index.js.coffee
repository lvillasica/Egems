class Egems.Views.ShiftSchedulesIndex extends Backbone.View

  template: JST['shift_schedules/index']

  events: ->
    'click #add-shift-btn' : 'addShift'

  initialize: ->
    @collection.on('add', @appendShift, this)
    @mixins = _.extend(this, Egems.Mixins.ShiftSchedules)

  render: ->
    $(@el).html(@template(shifts: @collection))
    this

  appendShift: (shift) ->
    nodata = $("#shifts-tbl tbody tr.nodata")
    if nodata.length > 0
      nodata.remove()

    rowId = shift.getId()
    @shiftView = new Egems.Views.ShiftSchedule(model: shift)

    $("#shifts-tbl tbody").append(@shiftView.render().el)


  addShift: (event) ->
    event.preventDefault()
    view = new Egems.Views.NewShiftSchedule()
    $('#main-container').fadeOut()
                        .after(view.render().el)
