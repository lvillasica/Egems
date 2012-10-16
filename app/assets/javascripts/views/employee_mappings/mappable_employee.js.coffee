class Egems.Views.MappableEmployee extends Backbone.View

  template: JST['employee_mappings/mappable_employee']
  tagName: 'option'
  
  events:
    'click': 'showMapping'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @model.on('change', @render, this)
  
  render: ->
    $(@el).html(@template(
      employee: @model
      mixins: $.extend(Egems.Mixins.Defaults)
    ))
    this
  
  showMapping: (event) ->
    event.preventDefault()
    $.ajax
      url: "/employee_mappings/#{ @model.id }"
      dataType: 'json'
      success: @onShowMappingSuccess
  
  onShowMappingSuccess: (data) =>
    supervisors = new Egems.Collections.EmployeeMappings(data.supervisors)
    proj_managers = new Egems.Collections.EmployeeMappings(data.project_managers)
    members = new Egems.Collections.EmployeeMappings(data.members)
    all_mapped = $.merge($.merge(data.supervisors, data.project_managers), data.members)
    supsView = new Egems.Views.MappedEmployees
      collection: supervisors
      all_mapped: all_mapped
      type: "Supervisors / TL's"
    pmsView = new Egems.Views.MappedEmployees
      collection: proj_managers
      all_mapped: all_mapped
      type: "Project Managers"
    membersView = new Egems.Views.MappedEmployees
      collection: members
      all_mapped: all_mapped
      type: "Members"
    $('#selected-employee-name').text(@model.fullName()).css('padding-bottom':'30px')
    $('#supervisors-lst').html(supsView.setSelectedEmployee(@model).render().el)
    $('#project-managers-lst').html(pmsView.setSelectedEmployee(@model).render().el)
    $('#members-lst').html(membersView.setSelectedEmployee(@model).render().el)
    @animateMappingContainer()
  
  animateMappingContainer: ->
    if $('.well.default').length >= 1
      $('.well.default').fadeOut 500, =>
        $('.well.default').remove()
        @showMappingContainer()
    else
      @showMappingContainer()
  
  showMappingContainer: ->
    $('#mapping-container').hide()
    $('.mapped-employees').removeClass('hidden')
    $('#mapping-container').slideDown(500)

