$(function() {
  var serverTime = new Date($("span#time").data('time'));
  var prependZero = function(num) {
    return (num < 10)? ("0" + num) : num;
  }
  
  setInterval(function() {
    serverTime.setSeconds(serverTime.getSeconds() + 1);
    var h = serverTime.getHours(),
        h_12hr = (h % 12),
        hh = prependZero((h_12hr == 0)? 12 : h_12hr),
        mm = prependZero(serverTime.getMinutes()),
        ss = prependZero(serverTime.getSeconds()),
        a = (h >= 12)? "pm" : "am";
    
    $('span#time').html(hh + ":" + mm + ":" + ss + " " + a);
  }, 1000);
});
