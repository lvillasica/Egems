class Egems.Views.Employee extends Backbone.View
  
  tagName: 'tr'
  events:
    'click': 'toggleCheckbox'
    'click .view': 'showLeaves'
    'click input[type="checkbox"]': 'stopPropagation'

  initialize: ->
    @template = @options.template

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
  
  showLeaves: (event) ->
    event.preventDefault()
    event.stopPropagation()
    alert @model.fullName()
  
  stopPropagation: (event) ->
    event.stopPropagation()
