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

  detailsHeader: (shift) ->
    header = """
             <tr class="shift_#{ shift.getId() }_details details-header">
               <td class="thin">Day</td>
               <td>AM Time In</td>
               <td>Duration</td>
               <td>Allowance</td>
               <td>PM Time In</td>
               <td>Duration</td>
               <td>Allowance</td>
              </tr>
             """

  displayShiftRow: (shift) ->
    actions = new Array

    if shift.isEditable()
      actions.push """
                   <a class="edit" href="#edit">
                     <i class="icon-edit" title="Edit Shift Schedule"></i>
                   </a>
                   """
    if shift.isCancelable()
      actions.push """
                   <a class="remove" href="#cancel">
                     <i class="icon-remove" title="Delete Shift Schedule"></i>
                   </a>
                   """

    row = """
          <th colspan='7'>
            <div class="pull-left">
              <a class="members" href="#employee">
                <i class="icon-user" title="View Employees"></i>
              </a> &nbsp;
              #{ shift.name() }
            </div>
            <span class="actions">#{ actions.join("&nbsp;") }</span>
          </th>
          """
