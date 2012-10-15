Egems.Mixins.EmployeeMappings =

  showEmployeeMappingForm: ->
    $('#employee-mapping-form-modal').append(this.render().el)
    $('#employee-mapping-form-header').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#employee-mapping-form-container').addClass('modal-body')
    $('#employee-mapping-form-actions').addClass('modal-footer')
    $('#employee-mapping-form-actions .cancel').attr('data-dismiss', 'modal')
    $('#employee-mapping-form-modal').modal(backdrop: 'static', 'show')
    $('#employee-mapping-form-modal').on 'hidden', ->
      $(this).remove()
