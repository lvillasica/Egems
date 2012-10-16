class Egems.Collections.Holidays extends Backbone.Collection

  url: '/hr/holidays'
  model: Egems.Models.Holiday

  parse: (response, xhr) ->
    this.searchRange = response.range
    return response.holidays
