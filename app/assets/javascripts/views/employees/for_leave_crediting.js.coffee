class Egems.Views.ForLeaveCrediting extends Backbone.View

  template: JST['employees/for_leave_crediting']
  
  events:
    "click #toggle-boxes" : "toggleCheckBoxes"
    "click #for-leave-crediting-form .grant": "grantEmployees"

  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @collection.on('reset', @render, this)

  render: ->
    $(@el).html(@template(employees: @collection))
    @collection.each(@appendEmployee)
    this

  appendEmployee: (employee) =>
    view = new Egems.Views.Employee
      model: employee
      template: JST['employees/for_leave_crediting_employee']
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

