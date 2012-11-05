class Egems.Views.NewLeave extends Backbone.View

  template: JST['leaves/new_leave']

  events:
    "click #leave-form-actions .submit" : "triggerSubmit"

  initialize: ->
    _.extend(this, Egems.Mixins.Leaves)
    if @options.special_types_only
      @form = new Egems.Views.SpecialTypeLeaveForm(collection: @collection)
    else
      #@form = new Egems.Views.LeaveForm()

  render: ->
    $(@el).html(@template())
    @$("#leave-form-container").append(@form.render().el)
    this

  triggerSubmit: (event) ->
    event.preventDefault()
    @$("#leave-form").attr("action", "/leaves").submit()
