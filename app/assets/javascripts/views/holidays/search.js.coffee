class Egems.Views.SearchHolidays extends Backbone.View

  initialize: ->
    @collection.on('reset', @listHolidays, this)

    @mixins = _.extend(this, Egems.Mixins.Defaults)
    @defaultDate = new Date(@collection.searchRange[0])
    @searchDiv   = $('<div id="holiday-search"></div>')

  render: ->
    $(@el).html(@searchDiv)
    @monthYearSelector(@searchDiv)
    this

  monthYearSelector: (dateFld, moreOpts = {}, useDefaultOpts = true) ->
    defaultOpts =
      showOtherMonths: false
      selectOtherMonths: false
      dateFormat: 'mm/dd/yy'
      onChangeMonthYear: (year, month, inst) =>
        @searchDate = new Date(year, month-1, 1)
        @gotoSelection()

    opts = if useDefaultOpts then $.extend(defaultOpts, moreOpts) else moreOpts
    $(dateFld).datepicker('destroy').datepicker(opts)
              .datepicker('setDate', @defaultDate)

  gotoSelection: ->
    searchDate_ = @mixins.format_date @searchDate
    $.ajax
      url: '/hr/holidays'
      type: 'GET'
      data: { 'searchRange' : searchDate_ }
      dataType: 'JSON'
      success: (data) =>
        @collection.reset(data.holidays)
        @searchDiv.val(searchDate_)

  listHolidays: ->
    tbl = $("#holidays-tbl tbody")
    tbl.children().remove()
    if @collection.length > 0
      @collection.each (holiday) ->
        view = new Egems.Views.Holiday(model: holiday)
        tbl.append(view.render().el)
    else
      tbl.append """
                 <tr>
                   <td colspan="5" class="well"><em>No holidays for this month.</em></td>
                 </tr>
                 """
