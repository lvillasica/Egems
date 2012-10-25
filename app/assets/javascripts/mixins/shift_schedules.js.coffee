Egems.Mixins.ShiftSchedules =
  tabbableShiftDetails: (days) ->
    navs = new Array
    divs = new Array

    _.each days, (day, index) ->
      navs.push """
                <li class="#{ if index == 0 then 'active' else '' }">
                  <a href="##{ day.toLowerCase() }" data-toggle="tab">#{ day }</a>
                </li>
                """
      divs.push """
                <div class="tab-pane #{ if index == 0 then 'active' else '' }" id="#{ day.toLowerCase() }">
                </div>
                """

    navs = '<ul class="nav nav-tabs">' + navs.join('') + '</ul>'
    divs = '<div class="tab-content">' + divs.join('') + '</div>'

    return navs + divs


  shiftDetailForm: ->
