class Egems.Views.Holiday extends Backbone.View

  template: JST['holidays/holiday']
  tagName: 'tr'

  initialize: ->
    @mixins = _.extend(this, Egems.Mixins.Defaults, Egems.Mixins.Holidays)

  events: ->
    'click a.edit' : 'editHoliday'
    'click a.remove' : 'deleteHoliday'

  render: ->
    $(@el).html(@template(
      holiday: @model
      mixins: @mixins
    ))
    this

  editHoliday: (event) ->
    event.preventDefault()
    view = new Egems.Views.EditHoliday(model: @model, modal: true)
    $('#main-container').append('<div id="apply-holiday-modal" class="modal hide fade" />')
    $('#apply-holiday-modal').append(view.render().el)
                           .modal(backdrop: 'static', 'show')
                           .on 'hidden', ->
                             $(this).remove()

  deleteHoliday: (event) ->
    event.preventDefault()
    if confirm "Are you sure?"
      destroy_path = '/hr/holidays/delete/' + @model.getId().toString()
      $.ajax
        url: destroy_path
        type: 'DELETE'
        dataType: 'JSON'
        success: (data) =>
          if data.errors != undefined
            @flashMsg data.errors
          else
            @flashMsg data.success
            @remove()
            @checkEmptyTable()

  checkEmptyTable: ->
    table = $('#holidays-tbl')
    if table.find('tbody tr').length == 0
      table.remove()
      $('#main-container').append('<div class="well">No data found.</div>')

  flashMsg: (msg) ->
    $('#flash_messages').html @mixins.flash_messages(msg)
