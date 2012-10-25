class Egems.Views.ShiftDetailForm extends Backbone.View

  template: JST['shift_details/form']

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults)
    @initValues()

  initValues: =>
    @dayNum      = @model.dayNum()
    @amStart     = @model.amStart()
    @amDuration  = @model.amDuration()
    @amAllowance = @model.amAllowance()
    @pmStart     = @model.pmStart()
    @pmDuration  = @model.pmDuration()
    @pmAllowance = @model.pmAllowance()

  render: ->
    $(@el).html(@template)
    @initFields()
    this

  initFields: =>
    @dayNumFld      = @$('#detail_day_of_week')
    @rateFld        = @$('#detail_rate')
    @amStartFld     = @$('#detail_am_time_start')
    @amDurationFld  = @$('#detail_am_time_duration')
    @amAllowanceFld = @$('#detail_am_time_allowance')
    @pmStartFld     = @$('#detail_pm_time_start')
    @pmDurationFld  = @$('#detail_pm_time_duration')
    @pmAllowanceFld = @$('#detail_pm_time_allowance')

    timePickerAttrs = { acceptNull: true, step: 15, timeFormat: 'h:i A' }
    @$('#detail_am_time_start').timepicker(timePickerAttrs)
    @$('#detail_pm_time_start').timepicker(timePickerAttrs)

    $(@el).find(":input:not(.timein)").change(@toDefaultValue)
    @dayNumFld.val(@dayNum).change => @dayNumFld.val(@dayNum)
    #time starts
    @amStartFld.val(@format_time_only(@amStart)).change(@changedTimein)
    @pmStartFld.val(@format_time_only(@pmStart)).change(@changedTimein)
    #durations
    @amDurationFld.val(@amDuration).keydown(@validateNumeric)
    @pmDurationFld.val(@pmDuration).keydown(@validateNumeric)
    #allowances
    @amAllowanceFld.val(@amAllowance).keydown(@validateNumeric)
    @pmAllowanceFld.val(@pmAllowance).keydown(@validateNumeric)


  toDefaultValue: (event) =>
    target = $(event.target)
    if target.val().trim().length == 0
      target.val('0')

  changedTimein: (event) =>
    fld = $(event.target)
    val = fld.val().trim()
    if val == "--:--" || val.length == 0
      grp = fld.parents("#" + @model.day().toLowerCase())
      grp.find(".timein").val("--:--")


  validateNumeric: (event) =>
    if !@isNumeric(event)
      event.preventDefault()
