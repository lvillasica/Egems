class Egems.Views.SpecialTypes extends Backbone.View

  template: JST['leaves/special_types']
  
  initialize: ->
    $('#add-special-type').click @addSpecialType
    @collection.on('reset', @render, this)
    @collection.on('add', @render, this)

  render: ->
    $(@el).html(@template(leaves: @collection))
    sortedLeaves = @collection.sortBy (l) -> l.employeeName()
    _.each(sortedLeaves, @appendLeaveEntry)
    @initActionsTooltip()
    this

  appendLeaveEntry: (leave) =>
    view = new Egems.Views.SpecialType(model: leave)
    @$('#special-types-leaves-tbl tbody').append(view.render().el)
    
  initActionsTooltip: ->
    $('#add-special-type').tooltip
      title: "Add Special Type of Leave to Employee"
      placement: 'left'
  
  addSpecialType: (event) =>
    event.preventDefault()
    $('#main-container').append('<div id="leave-form-modal" class="modal hide fade" />')
    view = new Egems.Views.NewLeave(collection: @collection, special_types_only: true)
    view.showLeaveForm()
