Egems.Mixins.LeaveDetails =
  leave_detail_actions: (leave_detail) ->
    actions = []
    if leave_detail.isEditable()
      actions.push """
        <a class="edit" href="/leave_details/#{leave_detail.getId()}/edit">
          <i class="icon-edit"></i>
        </a>
      """
    if leave_detail.isCancelable()
      actions.push """
        <a class="cancel" href="/leave_details/#{leave_detail.getId()}/cancel">
          <i class="icon-remove"></i>
        </a>
      """
    return actions.join("&nbsp;")
