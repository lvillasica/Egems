class Egems.Views.ShiftScheduleForm extends Backbone.View

  template: JST['shift_schedules/form']
  confirmSave: JST['shift_schedules/confirm']

  events: ->
    'submit #shift-form' : 'submitForm'

  initialize: ->
    @action  = this.options.action
    @days    = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    @mixins  = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.ShiftSchedules)
    @details = @model.details

  render: ->
    $(@el).html(@template(shift: @model, mixins: @mixins, days: @days))
    @initFields()
    @setupDetails()
    this

  initFields: ->
    name = @model.name()
    desc = @model.description()
    rate = @model.differentialRate()

    @form    = @$('#shift-form')
    @nameFld = @$('#shift_name')
    @descFld = @$('#shift_description')
    @rateFld = @$('#shift_rate')

    @nameFld.val(name)
            .blur(@validNotEmpty)
            .keyup(@validNotEmpty)
            .change => @model.set('name', @nameFld.val())

    @descFld.val(desc)
            .blur(@validNotEmpty)
            .keyup(@validNotEmpty)
            .change => @model.set('description', @descFld.val())

    @rateFld.val(rate)
            .keydown(@validateNumeric)
            .keyup(@validateRate)
            .change => @model.set('differential_rate', parseInt(@rateFld.val()))

  setupDetails: ->
    @$('#details-tabs').append(@tabbableShiftDetails(@days))
    if @action == 'create'
      _.each @days, (day) =>
        detailForm  = new Egems.Views.NewShiftDetail({ dayNum: @days.indexOf(day) })
        @$('#' + day.toLowerCase()).append(detailForm.render().el)
    else if @action == 'update'
      _.each @details.models, (detail) =>
        detailForm = new Egems.Views.EditShiftDetail(model: detail)
        day = detail.day()
        if day != undefined
          @$('#' + day.toLowerCase()).append(detailForm.render().el)

  submitForm: (event) ->
    event.preventDefault()
    if @validInput()
      data = @form.serialize()
      $.ajax
        url: @form.attr('action')
        data: data
        dataType: 'JSON'
        type: if @action == 'create' then 'POST' else 'PUT'
        beforeSend: (jqXHR, settings) =>
          @disableFormActions()
        success: (data) =>
          if data.errors != undefined
            @modalFlashMsg data.errors
            @enableFormActions()
          else
            $("#shift-form-container-wrapper").remove()
            shifts = new Egems.Routers.ShiftSchedules()
            shifts.index()
            $("#main-container").removeClass("slide-main-container")
            @flashMsg data.success

  validInput: ->
    @nameFld.trigger('blur')
    @descFld.trigger('blur')
    valid = true
    if @nameFld.parents('.control-group').hasClass('error') ||
       @descFld.parents('.control-group').hasClass('error')
      valid = false
    if @rateFld.val().length == 0
      @rateFld.val(0)
    return valid

  validateRate: =>
    fld = @rateFld
    r = parseInt(fld.val())
    if r > 100
      @addError(fld, "value from 0 to 100 only")
    else
      @removeError(fld)

  confirmInput: ->
    #TODO
    @form.hide()
    formContainer = @form.parents('.modal-body')
    formContainer.append(@confirmSave(shift: @model))
    return true

  validNotEmpty: (event) =>
    fld = $(event.target)
    txt = fld.val().trim()
    if txt.length == 0
      @addError(fld, "can't be blank")
    else
      @removeError(fld)

  validateNumeric: (event) =>
    if !@isNumeric(event)
      event.preventDefault()

  addError: (fld, error) ->
    grp = fld.parents('.control-group')
    grp.addClass('error')
    ctrl = grp.children('.controls')
    if ctrl.children('span.help-inline').length == 0
      ctrl.append("<span class='help-inline small'>" + error + "</span>")

  removeError: (fld) ->
    grp = fld.parents('.control-group')
    grp.removeClass('error')
    ctrl = grp.children('.controls')
    ctrl.children('span.help-inline').remove()

  enableFormActions: ->
    $('#shift-form-actions .submit').removeAttr('disabled')
    $('#shift-form-actions .cancel').removeAttr('disabled')

  disableFormActions: ->
    $('#shift-form-actions .submit').attr('disabled', true)
    $('#shift-form-actions .cancel').attr('disabled', true)

  findRowWithText: (txt) ->
    rows = $("th")
    frow = rows.filter (x) ->
      $(rows[x]).text() == txt
    frow.closest("tr")

  modalFlashMsg: (msg) ->
    $("#shift-form > #flash_messages").html @flash_messages(msg)

  flashMsg: (msg) ->
    $("#flash_messages").html @flash_messages(msg)
