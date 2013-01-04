class Egems.Views.HolidaysIndex extends Backbone.View

  template: JST['holidays/index']

  events: ->
    "click #add-holiday-btn": "addHoliday"

  render: ->
    $(@el).html(@template(holidays: @collection))
    @collection.each(@appendHoliday)
    @putHolidaySearch()
    this

  appendHoliday: (holiday) =>
    view = new Egems.Views.Holiday(model: holiday)
    @$("#holidays-tbl tbody").append(view.render().el)

  putHolidaySearch: (range) ->
    range = new Egems.Views.SearchHolidays(collection: @collection)
    @$('#holiday-actions-container').append(range.render().el)

  addHoliday: (event) ->
    event.preventDefault()
    searchDate = $("#holiday-search").val()
    view = new Egems.Views.NewHoliday(modal: true, defaultDate: searchDate)

    $('#main-container').append('<div id="apply-holiday-modal" class="modal hide fade" />')
    $('#apply-holiday-modal').append(view.render().el)
                           .modal(backdrop: 'static', 'show')
                           .on 'hidden', -> $(this).remove()
