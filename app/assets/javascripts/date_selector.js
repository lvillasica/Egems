
var dateSelector = function ( id, moreOpts, useDefaultOpts ) {

  useDefaultOpts = useDefaultOpts || true;
  moreOpts = moreOpts || {};
  
  var defaultOpts = {
    showOtherMonths: true,
    selectOtherMonths: true,
    showOn: "button",
    buttonText: "<i class='icon-calendar'></i>",
    dateFormat: 'yy-mm-dd'
  };
  
  var opts = (useDefaultOpts == true)? $.extend(defaultOpts, moreOpts) : moreOpts

  $('#' + id).datepicker('destroy').datepicker(opts);
  
  $('.ui-datepicker-trigger').addClass("btn");
  
}
