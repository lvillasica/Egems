class Egems.Views.ManualEntryForm extends Backbone.View
  template: JST['timesheets/manual_entry_form']
  id: 'manual-entry-form-container'
  
  events:
    'click #manual-entry-form-container .submit': 'triggerSubmit'
    'submit #manual-entry-form': 'submitForm'
  
  initialize: ->
    _.extend(this, Egems.Mixins.Defaults)
    @date = @options.date
    @modal = false
  
  render: ->
    $(@el).html(@template(date: @date))
    this
  
  showAsModal: ->
    @modal = true
    $('#manual-entry-form-container h3').wrap('<div class="modal-header" />')
    $('.modal-header').next('hr').remove()
    $('#form-body').addClass('modal-body')
    $('#form-controls').addClass('modal-footer')
    $('#form-controls .cancel').attr('data-dismiss', 'modal')
    $('#manual-entry-modal').modal(backdrop: 'static', 'show')
    $('#manual-entry-modal').on 'hidden', ->
      $(this).remove()
  
  triggerSubmit: (event) ->
    event.preventDefault()
    @$('#manual-entry-form').attr('action', '/timesheets/manual_time_entry')
    .submit()
  
  getAttributes: ->
    'timein[hour]': $('input[name="timein[hour]"]').val()
    'timein[min]': $('input[name="timein[min]"]').val()
    'timein[meridian]': $('select[name="timein[meridian]"]').val()
    'timein[date]': @date
    'timeout[hour]': $('input[name="timeout[hour]"]').val()
    'timeout[min]': $('input[name="timeout[min]"]').val()
    'timeout[meridian]': $('select[name="timeout[meridian]"]').val()
    'timeout[date]': $('input[name="timeout[date]"]').val()
  
  submitForm: (event) ->
    event.preventDefault()
    if @date is $('input[name="timein[date]"]').val()
      $.ajax
        url: $(event.target).attr('action')
        data: @getAttributes()
        dataType: 'json'
        type: 'POST'
        success: (data) =>
          if data.invalid_timesheet != null
            $('#manual-entry-modal').modal('hide')
            timesheet = new Egems.Views.TimesheetsIndex(collection: @collection)
            timesheet.manualTimeout(data.invalid_timesheet, data.error)
          else
            flash_messages = data.flash_messages
            if flash_messages is undefined or flash_messages.error is undefined
              $('#manual-entry-modal').modal('hide')
              $('#date-nav-tab li.day.active').trigger('click')
            else
              $('#flash_messages').html(@flash_messages(flash_messages))
    else
      alert "Spoofing alert! >:P"
      
