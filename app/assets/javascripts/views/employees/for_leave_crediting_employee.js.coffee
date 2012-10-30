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
    this
  
  toggleCheckbox: (event) ->
    event.preventDefault()
    checkbox = @$('input[type="checkbox"]')
    if checkbox.is(':checked')
      checkbox.removeAttr('checked')
    else
      checkbox.attr('checked', true)
  
  stopPropagation: (event) ->
    event.stopPropagation()
