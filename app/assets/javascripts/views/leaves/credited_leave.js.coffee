class Egems.Views.CreditedLeave extends Backbone.View

  template: JST['leaves/credited_leave']

  tagName: 'tr'

  events:
    'click a.save': 'saveAllocation'

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @model.on('change', @render, this)
    @model.on('highlight', @highlightRow, this)

  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    @initAllocFldFocusEvent()
    this

  highlightRow: ->
    setTimeout =>
      rowpos = $(@el).position().top - ($(window).height() / 2)
      $('html, body').animate({scrollTop: rowpos}, 'slow')
      $(@el).effect("highlight", {}, 5000)
    , 1000

  initAllocFldFocusEvent: ->
    @allocFld = @$('input[name="leave[leaves_allocated]"]')
    @allocFld.keyup @editAllocation

  editAllocation: (event) =>
    event.preventDefault()
    target = $(event.target)
    if @$('a.save').length is 0
      target.next('span.action')
      .append("<a class='save' href='#'><i class='icon-ok'></i></a>")
      @$('a.save').tooltip(title: 'Ok', placement: 'right')
      target.closest('tr').removeClass('error')

  saveAllocation: (event) ->
    event.preventDefault()
    @button = $(event.target)
    if @format_float(@allocFld.val()) != @format_float(@model.leavesAllocated())
      $.ajax
        url: "/leaves/#{ @model.id }"
        data: { leave: { leaves_allocated: @allocFld.val() } }
        dataType: 'json'
        type: 'PUT'
        success: @onSuccess
    else
      @resetAllocation()

  resetAllocation: ->
    @allocFld.val(@format_float @model.leavesAllocated())
    @$('a.save').tooltip('hide').remove()
    $('.alert').remove()

  onSuccess: (data) =>
    flash_messages = data.flash_messages
    @showFlash(flash_messages, null, @button.closest('div'))
    if flash_messages.error is undefined
      @$('a.save').tooltip('hide').remove()
      @model.set(data.leave)
      @model.trigger('highlight')
    else
      @button.closest('tr').addClass('error')
      @$('a.save').tooltip('hide').remove()
