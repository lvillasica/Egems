Egems.Mixins.Holidays =
  holiday_actions: (holiday) ->
    actions = new Array
    actions.push """
      <a class="edit" href="#">
        <i class="icon-edit"></i>
      </a>"""

    if holiday.isCancelable()
      actions.push """
        <a class="cancel" href="#">
          <i class="icon-remove"></i>
        </a> """

    return actions.join("&nbsp;")
