class Egems.Views.AccordionGroup extends Backbone.View
  template: JST['leaves/accordion_group']
  
  events:
    'click .accordion-toggle': 'toggleAccordion'
  
  render: ->
    $(@el).html(@template(leaveType: @collection))
    this
  
  toggleAccordion: (event) ->
    event.preventDefault()
    $(event.target).parent().next(".accordion-body").slideToggle(300)
