class Egems.Views.ForLeaveCrediting extends Backbone.View

  template: JST['employees/for_leave_crediting']
  
  events:
    "click #toggle-boxes" : "toggleCheckBoxes"
    "click #for-leave-crediting-form button.grant": "grantEmployees"
    "click #for-leave-crediting-form button.view": "viewEmployees"

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @collection.on('reset', @render, this)

  render: ->
    @grantedEmployees = new Egems.Collections.Employees()
    $(@el).html(@template(employees: @collection))
    @collection.each(@appendEmployee)
    @$('#for-leave-crediting-form button.view').tooltip
      title: "View Granted Employees"
      placement: 'right'
    this

  appendEmployee: (employee) =>
    view = new Egems.Views.ForLeaveCreditingEmployee(model: employee)
    @$("#employees-tbl tbody").append(view.render().el)
  
  toggleCheckBoxes: (event) ->
    event.preventDefault()
    className  = $('#toggle-boxes')[0].className
    checkBoxes = $("#for-leave-crediting-form input[type='checkbox']:not(:disabled)")
    switch className
      when "icon-ok"
        $(event.target).removeClass('icon-ok').addClass('icon-remove')
        checkBoxes.attr('checked', true)
      when "icon-remove"
        $(event.target).removeClass('icon-remove').addClass('icon-ok')
        checkBoxes.attr('checked', false)
  
  getCheckedIds: ->
    _.map $("#for-leave-crediting-form input[type='checkbox']:checked"), (box) ->
      $(box).val()
  
  grantEmployees: (event) ->
    event.preventDefault()
    ids = @getCheckedIds()

    if ids.length > 0
      if confirm "Are you sure?"
        $.ajax
          url: '/leaves/grant'
          data: { qualified_ids: ids }
          dataType: 'JSON'
          type: 'POST'
          success: @onSuccessfulGrant
    else
      alert 'No employees selected.'
  
  onSuccessfulGrant: (data) =>
    @collection.fetch
      url: '/employees/for_leave_crediting'
      success: (collection, response) =>
        @collection.reset(response.for_leave_crediting)
    @showFlash(data.flash_messages, null, '#qualified-for-leaves-container')
  
  viewEmployees: (event) ->
    event.preventDefault()
    @toggleViewContainer(event)
    @renderRootView()
  
  toggleViewContainer: (event) ->
    @target = $(event.target)
    @toggleContents = $('#qualified-for-leaves-container .toggle-contents')
    @setArrowPos(@target)
    @toggleContents.slideToggle 300, =>
      unless @toggleContents.is(':hidden')
        unless @grantedEmployees.length > 0 or @toggleContents.find('.contents:contains("No data")').length > 0
          @renderGrantedEmployeesView()
  
  setArrowPos: (target) ->
    arrowPos = ((target.innerWidth() / 2) + @getViewBtnLeftPos(target) - 10)
    @toggleContents.find('.arrow-up').css(left: "#{ arrowPos }px")
  
  getViewBtnLeftPos: (viewBtn) ->
    parent = $('#qualified-for-leaves-container')
    o1 = viewBtn.offset()
    o2 = parent.offset()
    leftPos = o1.left - o2.left
  
  renderGrantedEmployeesView: ->
    year = parseInt(I18n.strftime(new Date(), "%Y"))
    @grantedEmployees.fetch
      url: '/employees/leaves_credited'
      data: { year: year }
      success: (collection, response) =>
        @grantedEmployees.reset(response.granted_employees)
        view = new Egems.Views.LeavesCredited
          collection: @grantedEmployees
          year: year
        @toggleContents.find('.contents').html(view.render().el)
  
  renderRootView: ->
    rootLnk = @toggleContents.find('a.root')
    rootLnk.trigger('click') unless rootLnk.length is 0

