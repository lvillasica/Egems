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
    popoverContent = "You have #{ totalPending } leaves waiting for approval."
    $('#notif').attr('data-content', popoverContent)
    $('#total_pending_leaves').html(totalPending)
