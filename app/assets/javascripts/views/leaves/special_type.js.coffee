class Egems.Views.SpecialType extends Backbone.View

  template: JST['leaves/special_type']
  
  tagName: 'tr'
  
  events:
    'click .edit': 'editLeave'
    'click .delete': 'deleteLeave'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @model.on('change', @render, this)
    @model.on('highlight', @highlightRow, this)
  
  render: ->
    $(@el).html(@template(
      leave: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Leaves)
    ))
    @initActionsTooltip()
    this
  
  initActionsTooltip: ->
    @$('.edit').tooltip(title: "Edit")
    @$('.delete').tooltip(title: "Delete")
  
  highlightRow: ->
    setTimeout =>
      rowpos = $(@el).position().top - ($(window).height() / 2)
      $('html, body').animate({scrollTop: rowpos}, 'slow')
      $(@el).effect("highlight", {}, 5000)
    , 1000
  
  editLeave: (event) ->
    event.preventDefault()
    $('#main-container').append('<div id="leave-form-modal" class="modal hide fade" />')
    view = new Egems.Views.EditLeave
      model: @model
      special_types_only: true
    view.showLeaveForm()
  
  deleteLeave: (event) ->
    event.preventDefault()
    if confirm 'Are you sure?'
      $.ajax
        url: "/leaves/#{ @model.id }"
        dataType: 'json'
        type: 'DELETE'
        success: @onSuccessDelete
  
  onSuccessDelete: (data) =>
    $(@el).effect("highlight").fadeOut(1000, -> $(this).remove())
    @collection = @model.collection
    @collection.remove(@model)
    @tbl = $("#special-types-leaves-tbl")
    @tblCont = @tbl.parent()
    @showFlash(data.flash_messages, null, @tblCont)
    @removeTable() if @collection.length is 0
  
  removeTable: ->
    @tbl.fadeOut 1000, =>
      @tbl.remove()
      @tblCont.append('<p class="well">No data found.</p>').hide().fadeIn('fast')

