Egems.Mixins.Holidays =
  holiday_actions: (holiday) ->
    actions = new Array
    if holiday.isEditable()
      actions.push """
        <a class="edit" href="#">
          <i class="icon-edit"></i>
        </a>"""

    if holiday.isCancelable()
      actions.push """
        <a class="remove" href="#">
          <i class="icon-remove"></i>
        </a> """

    return actions.join("&nbsp;")
