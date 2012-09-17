Egems.Mixins.Leaves =
  noLeaveModal: (error, options) ->
    errorMsg = Egems.Mixins.Defaults.flash_messages(error)
    closeBtn = """
               <div id="leave-detail-form-actions" class="form-actions modal-footer">
                 <button class="btn pull-right" data-dismiss="modal">Close</button>
               </div>
               """
    if options.isModal == true
      header = """
               <div>
                <div class="modal-header">
                  <h3>New Leave Application</h3>
                </div>
               </div>
               """
      body = "<div class='modal-body'>" + errorMsg + "</div>"
      return header + body + closeBtn
    else
      return errorMsg
  
  updateNotif: (totalPending) ->
    p = Egems.Mixins.Defaults.simplePluralize
    popoverContent = "You have #{ p totalPending, 'leave' } waiting for approval."
    @insertNotif() if $('#notif').length is 0
    $('#notif').attr('data-content', popoverContent)
    $('#total_pending_leaves').html(totalPending)
  
  insertNotif: ->
    nav = $('#user-control-nav')
    $("""
    <li class="divider-vertical"></li>
    <li>
      <a id="notif" href="/leaves">
        <span class="badge badge-important">
	        <span id="total_pending_leaves"></span>
	        <i class="icon-flag icon-white"></i>
	      </span>
      </a>
    </li>
    """)
    .insertAfter(nav.find('li:first'))
    $('#notif').popover(title: 'Notifications', placement: 'bottom', content: '')
  
