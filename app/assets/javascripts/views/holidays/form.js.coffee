class Egems.Views.HolidayForm extends Backbone.View

  template: JST['holidays/form']

  initialize: ->
    @mixins   = _.extend(Egems.Mixins.Defaults, Egems.Mixins.Holidays)
    @branches = new Egems.Collections.Branches()
    @branches.fetch
      async: false
    @branch_ids = null

  events: ->
    "click #holiday_branch_all" : "selectAllBranches"
    "click #holiday_branch_specific" : "selectSpecBranch"
    "submit #holiday-form" : "submitForm"

  render: ->
    $(@el).html(@template(holiday: @model, branches: @branches))
    @initFields()
    @setFormValues()
    this

  initFields: ->
    @dateFld = @$('#holiday_date')
    @descFld = @$('#holiday_description')
    @nameFld = @$('#holiday_name')
    @allBranchRadio  = @$("#holiday_branch_all")
    @specBranchRadio = @$("#holiday_branch_specific")
    @branchSelect    = @$("#holiday_branch_select")

    @branchSelect.change =>
      @branch_ids = new Array(@branchSelect.val())


  setFormValues: ->
    nextDay = new Date().addDays(1)
    @dateFld.val(@mixins.format_date nextDay)
    @dateSelector(@dateFld, {minDate: nextDay})
    @selectAllBranches()

  selectAllBranches: ->
    @allBranchRadio.attr('checked', true)
    @specBranchRadio.attr('checked', false)
    @branchSelect.attr('disabled', true)
    @branch_ids = _.collect @branches.models, (b) -> b.getId().toString()

  selectSpecBranch: ->
    @specBranchRadio.attr('checked', true)
    @allBranchRadio.attr('checked', false)
    @branchSelect.attr('disabled', false)
    @branch_ids = new Array(@branchSelect.val())

  dateSelector: (dateFld, moreOpts = {}, useDefaultOpts = true) ->
    defaultOpts =
      showOtherMonths: true
      selectOtherMonths: true
      showOn: "button"
      buttonText: "<i class='icon-calendar'></i>"
      dateFormat: 'yy-mm-dd'
      onSelect: @onDateSelect
    opts = if useDefaultOpts then $.extend(defaultOpts, moreOpts) else moreOpts
    $(dateFld).datepicker("destroy").datepicker(opts)
    $(dateFld).next('.ui-datepicker-trigger').addClass("btn")

  onDateSelect: (dateText, inst) =>
    @model.set(inst.id.substring(13), dateText)

  submitForm: (event) ->
    event.preventDefault()
    form = $("#holiday-form")
    data = form.serialize() + "&" + $.param({'branch_ids' : @branch_ids})
    $.ajax
      url: form.attr('action')
      data: data
      dataType: 'JSON'
      type: 'POST'
      beforeSend: (jqXHR, settings) =>
        @disableFormActions()
      success: (data) =>
        if data.errors != undefined
          @modalFlashMsg data.errors
        else
          @exitForm()
          holidays = new Egems.Routers.Holidays()
          holidays.index()
          @flashMsg data.success

  exitForm :->
    $('#apply-holiday-modal').remove()
    $('.modal-backdrop').remove()
    $('#loading-indicator').hide()

  inModal: ->
    $('#holiday-form').parents('#apply-holiday-modal').length == 1

  enableFormActions: ->
    $('#leave-detail-form-actions .submit').removeAttr('disabled')
    $('#leave-detail-form-actions .cancel').removeAttr('disabled')

  disableFormActions: ->
    $('#leave-detail-form-actions .submit').attr('disabled', true)
    $('#leave-detail-form-actions .cancel').attr('disabled', true)

  modalFlashMsg: (msg) ->
    $("#holiday-form > #flash_messages").html @mixins.flash_messages(msg)

  flashMsg: (msg) ->
    $("#flash_messages").html @mixins.flash_messages(msg)
