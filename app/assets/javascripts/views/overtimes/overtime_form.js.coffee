class Egems.Views.OvertimeForm extends Backbone.View

  
  template: JST['overtimes/overtime_form']

  events:
    'submit #overtime_form': 'submitForm'

  initialize: ->
    @overtimeDuration = @$('#overtime_duration').val()
    @workDetail = @$('#overtime_work_details').val()

  initFields: ->
    @overtimeDuration = @$('#overtime_duration')
    @workDetail = @$('#overtime_work_details')

  render: ->
    $(@el).html(@template())
    this

  submitForm: (event) ->
    event.preventDefault()
    attributes = 
      'work_details': @workDetail.val()
      'duration': @overtimeDuration.val()
     $.ajax
      url: @$("#overtime_form").attr('action')
      data: {'overtimes': attributes}
      dataType: 'json'
      type: if @options.edit then 'PUT' else 'POST'
      success: (data) =>
        flash_messages = data.flash_messages