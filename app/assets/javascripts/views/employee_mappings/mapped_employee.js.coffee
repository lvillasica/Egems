class Egems.Views.MappedEmployee extends Backbone.View

  template: JST['employee_mappings/mapped_employee']
  tagName: 'tr'
  
  events:
    'click .actions a.edit': 'editMapping'
    'click .actions a.delete': 'deleteMapping'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @selectedEmployee = @options.selectedEmployee
    @type = @options.type
    @mapped_employees_view = @options.mapped_employees_view
    @model.on('change', @render, this)
    @model.on('highlight', @highlightRow, this)
  
  render: ->
    $(@el).html(@template(
      employee: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
  
  highlightRow: ->
    setTimeout =>
      rowpos = $(@el).position().top - ($(window).height() / 2)
      $('html, body').animate({scrollTop: rowpos}, 'slow')
      $(@el).effect("highlight", {}, 5000)
    , 1000
  
  editMapping: (event) ->
    event.preventDefault()
    $('#main-container').append('<div id="employee-mapping-form-modal" class="modal hide fade" />')
    view = new Egems.Views.EditMapping
      model: @model
      selectedEmployee: @selectedEmployee
      type: @type
    view.showEmployeeMappingForm()
  
  deleteMapping: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      $.ajax
        url: "/employee_mappings/#{ @model.id }"
        data: { 'employee_mapping': {'approver_id': @model.approverId()} }
        dataType: 'json'
        type: 'DELETE'
        success: @onSuccessDelete
  
  onSuccessDelete: (data) =>
    $(@el).effect("highlight").fadeOut(1000, -> $(this).remove())
    id = if @type is 'Member' then @model.employeeId() else @model.approverId()
    @mapped_employees_view.all_mapped = _.filter @mapped_employees_view.all_mapped, (mapped) =>
      return mapped unless mapped.full_name is @model.fullName()
    @showFlash(data.flash_messages, null, '#mapping-container')

