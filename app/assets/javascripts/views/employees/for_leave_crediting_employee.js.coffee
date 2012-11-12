class Egems.Views.ForLeaveCreditingEmployee extends Backbone.View

  template: JST['employees/for_leave_crediting_employee']

  tagName: 'tr'

  events:
    'click': 'toggleCheckbox'
    'click input[type="checkbox"]': 'stopPropagation'

  render: ->
    $(@el).html @template
      employee: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    @setSelected()
    this

  setSelected: ->
    @checkbox = @$('input[type="checkbox"]')
    @checkbox.change =>
      if @checkbox.is(':checked')
        $(@el).addClass('selected')
      else
        $(@el).removeClass('selected')

  toggleCheckbox: (event) ->
    event.preventDefault()
    if @checkbox.is(':checked')
      @checkbox.removeAttr('checked')
    else
      @checkbox.attr('checked', true)
    @checkbox.trigger('change')

  stopPropagation: (event) ->
    event.stopPropagation()
