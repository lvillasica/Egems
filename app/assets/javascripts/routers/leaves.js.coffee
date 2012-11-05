class Egems.Routers.Leaves extends Backbone.Router
  routes:
    'leaves': 'index'
    'leaves/crediting': 'crediting'
  
  initializeCollection: ->
    @collection = new Egems.Collections.Leaves()
    data = $('#data-container').data('leaves')
    if data is not undefined
      @collection.reset(data)
    else
      @collection.fetch
        async: false
        success: (collection, response) =>
          @collection.reset(response.leaves)
  
  index: ->
    @initializeCollection()
    index = new Egems.Views.LeavesIndex(collection: @collection)
    leaves_accordion = new Egems.Views.LeavesAccordion(collection: @collection)
    $('#main-container').html(index.render().el)
    $('#leave_details_container').html(leaves_accordion.render().el)
  
  crediting: ->
    years = $('#data-container').data('years')
    leavesCrediting = new Egems.Views.LeavesCrediting(years: years)
    $('#main-container').html(leavesCrediting.render().el)
    @forCreditingEmployees = new Egems.Collections.Employees()
    @forCreditingEmployees.fetch
      url: '/employees/for_leave_crediting'
      success: @renderForLeaveCrediting
    @specialTypes = new Egems.Collections.Leaves()
    @specialTypes.fetch
      url: '/leaves/special_types'
      success: @renderSpecialTypes
  
  renderForLeaveCrediting: (collection, response) =>
    @forCreditingEmployees.reset(response.for_leave_crediting)
    forLeaveCrediting = new Egems.Views.ForLeaveCrediting
      collection: @forCreditingEmployees
    $('#qualified-for-leaves-container').html(forLeaveCrediting.render().el)
  
  renderSpecialTypes: (collection, response) =>
    @specialTypes.reset(response.special_types)
    view = new Egems.Views.SpecialTypes(collection: @specialTypes)
    $('#other-types-of-leaves-container').html(view.render().el)
    
