class Egems.Views.ShiftSchedulesIndex extends Backbone.View

  template: JST['shift_schedules/index']

  events: ->
    'click #add-shift-btn' : 'addShift'

  initialize: ->
    @collection.on('add', @appendShift, this)
    @mixins = _.extend(this, Egems.Mixins.ShiftSchedules, Egems.Mixins.Defaults)

  render: ->
    $(@el).html(@template(shifts: @collection))
    @initDivs()
    this

  initDivs: ->
    @indexDiv = $(@el).first()
    @indexDiv.attr('id', 'shifts-index-container')
    @mainDiv = $("#main-container")
    if @mainDiv.parents(".slide-container").length == 0
      @mainDiv.wrap("<div class='slide-container'/>")

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
    if $(".shift-form-container-wrapper").length == 0
      form = $(view.render().el)
      @indexDiv.after(form)
      @mainDiv.addClass("slide-main-container")
      @slideEffect(@indexDiv, form)
