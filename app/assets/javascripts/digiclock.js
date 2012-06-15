$(function() {
  // used datejs to parse or format date.
  var serverTime = Date.parse($("span#time").data('time'));
  
  setInterval(function() {
    serverTime.setSeconds(serverTime.getSeconds() + 1);
    var time = serverTime.toString("hh:mm:ss tt").toLowerCase();
    $('span#time').html(time);
  }, 1000);
});
