class Egems.Views.TimeEntry extends Backbone.View
  template: JST['timesheets/time_entry']
  tagName: 'tr'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Timesheets, Egems.Mixins.Defaults)
    @model.on('change', @renderChanged, this)
    @model.on('highlight', @highlightRow, this)
    @model.on('editEntry', @editEntry, this)
  
  render: ->
    $(@el).html(@template(
      timeEntry: @model
      mixins: $.extend(Egems.Mixins.Defaults, Egems.Mixins.Timesheets)
      size: @model.collection.length
    ))
    this
  
  renderChanged: ->
    collection = @model.collection
    remarks = collection.first().remarks()
    str = ''
    for remark in @showRemarks(remarks)
      str += " <span class='remarks-text'>#{ remark }</span><br/>"
    $('.remarks').html(str)
    .attr('class', "remarks #{ @classRemarks(remarks) }")
    .attr('title', @titleRemarks(remarks))
    $('.duration').html(@format_in_hours(collection.sum_minutes('duration')))
    $('.late').html(@format_in_hours(collection.sum_minutes('minutes_late')))
    $('.undertime').html(@format_in_hours(collection.sum_minutes('minutes_undertime')))
    $('.excess').html(@format_in_hours(collection.sum_minutes('minutes_excess')))
  
  highlightRow: ->
    rowpos = $(@el).position().top - ($(window).height() / 2)
    $('html, body').animate({scrollTop: rowpos}, 'slow')
    $(@el).find('.time.in, .time.out').effect("highlight", {}, 5000)
  
  editEntry: ->
    switch @model.validity()
      when 2
        form = new Egems.Views.EditEntryForm(model: @model)
        form.setAction('timeout').setTime(@model.timeOut())
        $(@el).find('.time.out').html(form.render().el)
      when 3
        form = new Egems.Views.EditEntryForm(model: @model)
        form.setAction('timein').setTime(@model.timeIn())
        $(@el).find('.time.in').html(form.render().el)
      when 4
        form1 = new Egems.Views.EditEntryForm(model: @model)
        form1.setAction('timein').setTime(@model.timeIn())
        $(@el).find('.time.in').html(form1.render().el)
        form2 = new Egems.Views.EditEntryForm(model: @model)
        form2.setAction('timeout').setTime(@model.timeOut())
        $(@el).find('.time.out').html(form2.render().el)

