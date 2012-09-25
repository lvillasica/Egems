Egems.Mixins.Overtimes =
  overtime_actions: (overtime) ->
    actions = []
    if _.include(['Pending', 'Rejected'], overtime.status())
      actions.push """
        <a class="edit" href="/overtimes/#{ overtime.getId() }/edit">
          <i class="icon-edit"></i>
        </a>
      """
      
      actions.push """
        <a class="cancel" href="/overtimes/#{ overtime.getId() }/cancel">
          <i class="icon-remove"></i>
        </a>
      """
    return actions.join("&nbsp;")
