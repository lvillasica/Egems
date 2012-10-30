class Egems.Views.LeavesCrediting extends Backbone.View
  
  template: JST['leaves/leaves_crediting']
  
  events:
    'click #annual-leave-credit-form .grant': 'grantEmployees'
    'click #annual-leave-credit-form .view': 'viewEmployees'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @years = @options.years
    @grantedEmployees = new Egems.Collections.Employees()

  render: ->
    $(@el).html(@template(years: @years))
    @initYearsFld()
    $(window).resize => @setArrowPos(@$('.controls .view'))
    this
  
  renderGrantedEmployeesView: ->
    @grantedEmployees.fetch
      url: '/employees/leaves_credited'
      data: { year: @yearsFld.val() }
      success: (collection, response) =>
        @grantedEmployees.reset(response.granted_employees)
        view = new Egems.Views.LeavesCredited
          collection: @grantedEmployees
          year: parseInt(@yearsFld.val())
        @$('.toggle-contents .contents').html(view.render().el)
  
  resetGrantedEmployees: =>
    @renderRootView()
    if @$('.toggle-contents').is(':hidden')
      $('.toggle-contents .contents').html(@smallLoadingIndicator())
      @grantedEmployees.reset()
    else
      @renderGrantedEmployeesView()
    
  initYearsFld: ->
    @yearsFld = @$('select[name="year"]')
    for year in @years
      @yearsFld.append("<option value='#{ year }'>#{ year }</option>")
    @yearsFld.change @resetGrantedEmployees
  
  grantEmployees: (event) ->
    event.preventDefault()
    if confirm 'Are you sure?'
      @renderRootView()
      $.ajax
        url: '/leaves/grant'
        data: {year: @yearsFld.val()}
        dataType: 'JSON'
        type: 'POST'
        success: @onSuccessfulGrant
  
  onSuccessfulGrant: (data) =>
    @showFlash(data.flash_messages, null, '#annual-leave-credit-form-container')
    @resetGrantedEmployees()
  
  viewEmployees: (event) ->
    event.preventDefault()
    @toggleViewContainer(event)
    @renderRootView()
  
  toggleViewContainer: (event) ->
    @setArrowPos($(event.target))
    @$('.toggle-contents').slideToggle 300, =>
      unless @$('.toggle-contents').is(':hidden')
        unless @grantedEmployees.length > 0 or $('.contents:contains("No data")').length > 0
          @renderGrantedEmployeesView()
  
  setArrowPos: (target) ->
    arrowPos = ((target.innerWidth() / 2) + @getViewBtnLeftPos(target) - 10)
    @$('.arrow-up').css(left: "#{ arrowPos }px")
  
  getViewBtnLeftPos: (viewBtn) ->
    parent = @$('#annual-leave-credit-form-container')
    o1 = viewBtn.offset()
    o2 = parent.offset()
    leftPos = o1.left - o2.left
  
  renderRootView: ->
    rootLnk = $('a.root')
    rootLnk.trigger('click') unless rootLnk.length is 0

