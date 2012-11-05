class Egems.Views.ShiftSchedule extends Backbone.View

  tagName: 'tr'
  className: "shift-schedule"

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.ShiftSchedules, Egems.Mixins.Defaults)
    @rowId  = 'shift_' + @model.getId()

  events: ->
    'click .icon-edit'   : 'editShift'
    'click .icon-remove' : 'cancelShift'
    'click .icon-user'   : 'viewEmployees'

  render: ->
    $(@el).html(@displayShiftRow(@model))
    @attrShift()
    @putDetails()
    this

  attrShift: ->
    $(@el).attr('id', @rowId)
          .click @rowClick

  rowClick: (event) =>
    event.preventDefault()
    target = event.target
    if target.className != 'icon-edit' && target.className != 'icon-remove' && target.className != 'icon-user'
      @showDetails(target)

  putDetails: ->
    @details = new Egems.Collections.ShiftDetails({shiftId: @model.getId()})
    @details.fetch
      add: true
      success: =>
        @model.details = @details
        $(@detailsHeader(@model)).insertAfter($(@el)).css('display', 'none')
    @details.on('add', @appendDetails, this)

  appendDetails: (detail) ->
    detailView = new Egems.Views.ShiftDetail(model: detail)
    $(detailView.render().el).insertAfter($(@el)).css('display', 'none')

  showDetails: (row) ->
    $(@el).toggleClass('open')
    $('.' + @rowId + '_details').toggle()

  editShift: (event) ->
    event.preventDefault()
    view = new Egems.Views.EditShiftSchedule(model: @model)
    $('#main-container').fadeOut()
                        .after(view.render().el)

  cancelShift: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      destroy_path = '/hr/shifts/delete/' + @model.getId().toString()
      $.ajax
        url: destroy_path
        type: 'DELETE'
        dataType: 'JSON'
        success: (data) =>
          if data.errors != undefined
            @flashMsg data.errors
          else
            @flashMsg data.success
            $('.' + @rowId + '_details').remove()
            @remove()
            @checkEmptyTable()

  checkEmptyTable: ->
    table = $('#shifts-tbl')
    if table.find('tbody tr').length == 0
      table.append '<tr><td colspan="7" class="well"><em>No data found.</em></td></tr>'

  flashMsg: (msg) ->
    $('#flash_messages').html @mixins.flash_messages(msg)

  viewEmployees: (event) ->
    event.preventDefault()
    view = new Egems.Views.ShiftScheduleEmployees(model: @model)
    $('#main-container').fadeOut()
                        .after(view.render().el)
