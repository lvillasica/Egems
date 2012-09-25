class Egems.Views.Overtime extends Backbone.View

  template: JST['overtimes/overtime']
  tagName: 'tr'
  
  events:
    'click a.edit': 'editOvertime'
    'click a.cancel': 'cancelOvertime'

  initialize: ->
    @model.on('change', @render, this)
    @model.on('highlight', @highlightRow, this)

  render: ->
    $(@el).html(@template(
      overtime: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets, Egems.Mixins.Overtimes)
      ))
    @initActionsTooltip()
    this
  
  initActionsTooltip: ->
    @$('.edit').tooltip(title: "Edit")
    @$('.cancel').tooltip(title: "Cancel")
  
  highlightRow: ->
    setTimeout =>
      rowpos = $(@el).position().top - ($(window).height() / 2)
      $('html, body').animate({scrollTop: rowpos}, 'slow')
      $(@el).effect("highlight", {}, 5000)
    , 1000
  
  editOvertime: (event) ->
    event.preventDefault()
    $('#main-container').append('<div id="overtime-form-modal" class="modal hide fade" />')
    $.ajax
      url: event.currentTarget.pathname
      dataType: 'json'
      success: (data) =>
        if data.error_response
          alert data.error_response
        else
          model = new Egems.Models.Overtime(data.overtime)
          view = new Egems.Views.EditOvertimeEntry(model: model, oldData: @model)
          view.showOvertimeForm()
  
  cancelOvertime: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      alert event.currentTarget.pathname
