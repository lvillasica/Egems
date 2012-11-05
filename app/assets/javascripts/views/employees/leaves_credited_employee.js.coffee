class Egems.Views.LeavesCreditedEmployee extends Backbone.View

  template: JST['employees/leaves_credited_employee']
  
  tagName: 'tr'
  
  events:
    'click .view': 'showLeaves'
  
  initialize: ->
    @creditedLeaves = new Egems.Collections.Leaves()
    @year = @options.year

  render: ->
    $(@el).html @template
      employee: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    this
  
  showLeaves: (event) ->
    event.preventDefault()
    @showLeavesTarget = $(event.target)
    @creditedLeaves.fetch
      url: '/leaves/credited'
      data: { employee_id: @model.id, year: @year }
      success: @renderLeavesView
  
  renderLeavesView: (collection, response) =>
    @creditedLeaves.reset(response.credited_leaves)
    view = new Egems.Views.CreditedLeaves(collection: @creditedLeaves)
    @toggleView = @showLeavesTarget.parents('.toggle-contents')
    title = @toggleView.find('.title')
    title.append("<span class='active'>#{ @model.fullName() }</span>")
    title.find('span:first').wrapInner('<a href="#" class="root">')
    $('<span class="divider"> / </span>').insertAfter(title.find('span:first'))
    @toggleView.find('.contents').html(view.render().el)
    $('.root').click @renderRootView
  
  renderRootView: (event) =>
    event.preventDefault()
    view = new Egems.Views.LeavesCredited
      collection: @model.collection
      year: @year
    @toggleView.find('.title').html('<span>Granted Employees</span>')
    @toggleView.find('.contents').html(view.render().el)
    
