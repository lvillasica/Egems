class Egems.Views.Leave extends Backbone.View
  template: JST['leaves/leave']
  tagName: 'tr'
  
  events:
    'click td span.focusable': 'focusAccordion'
  
  initialize: ->
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
  
  focusAccordion: (event) ->
    event.preventDefault()
    target = $("##{ @model.leaveType().replace(/\s/g, '') }")
    $(".accordion-body").hide()
    target.closest(".accordion-body").slideDown(300)
    rowpos = target.position().top - ($(window).height() / 2)
    $('html, body').animate({scrollTop: rowpos}, 'slow')
