class Egems.Views.LeavesAccordion extends Backbone.View

  template: JST['leaves/leaves_accordion']

  render: ->
    $(@el).html(@template())
    leaveTypes = _.uniq(_.map(@collection.models, (l) -> l.leaveType()))
    _.each(leaveTypes, @appendLeave)
    this

  appendLeave: (leaveType) =>
    leaveTypeTrimmed = leaveType.replace(/\s/g, "")
    # synchronous ajax to maintain ordering
    $.ajax
      async: false
      type: 'GET'
      dataType: 'json'
      url: "/leave_details/of_type/#{ leaveType }"
      success: (data) =>
        collection = new Egems.Collections.LeaveDetails()
        collection.reset(data.leave_details)
        leaveDetailsIndex = new Egems.Views.LeaveDetailsIndex(collection: collection, leaves: @collection)
        accordionGroup = new Egems.Views.AccordionGroup(collection: leaveType)
        @$('#accordion2').append(accordionGroup.render().el)
        @$("#accordion2 ##{ leaveTypeTrimmed } .accordion-inner").html(leaveDetailsIndex.render().el)
