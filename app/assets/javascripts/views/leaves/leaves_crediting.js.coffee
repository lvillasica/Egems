class Egems.Views.LeavesCrediting extends Backbone.View
  
  template: JST['leaves/leaves_crediting']
  
  events:
    'click #annual-leave-credit-form .grant': 'grantEmployees'
    'click #annual-leave-credit-form .view': 'viewEmployees'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @years = @options.years

  render: ->
    $(@el).html(@template(years: @years))
    @initYearsFld()
    $(window).resize => @setArrowPos(@$('.controls .view'))
    this
  
  initYearsFld: ->
    @yearsFld = @$('select[name="year"]')
    for year in @years
      @yearsFld.append("<option value='#{ year }'>#{ year }</option>")
  
  grantEmployees: (event) ->
    event.preventDefault()
    if confirm 'Are you sure?'
      $.ajax
        url: '/leaves/grant'
        data: {year: @yearsFld.val()}
        dataType: 'JSON'
        type: 'POST'
        success: @onSuccessfulGrant
  
  onSuccessfulGrant: (data) =>
    @showFlash(data.flash_messages)
  
  viewEmployees: (event) ->
    event.preventDefault()
    @toggleViewContainer(event)
  
  toggleViewContainer: (event) ->
    @setArrowPos($(event.target))
    @$('.toggle-contents').slideToggle(300)
  
  setArrowPos: (target) ->
    arrowPos = ((target.innerWidth() / 2) + @getViewBtnLeftPos(target) - 10)
    @$('.arrow-up').css(left: "#{ arrowPos }px")
  
  getViewBtnLeftPos: (viewBtn) ->
    parent = @$('#annual-leave-credit-form-container')
    o1 = viewBtn.offset()
    o2 = parent.offset()
    leftPos = o1.left - o2.left

