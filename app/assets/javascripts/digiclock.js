$(function() {
  var serverTime = Date.parse($("span#time").data('time'));
  
  setInterval(function() {
    serverTime.setSeconds(serverTime.getSeconds() + 1);
    
    $('span#time').html(serverTime.toCustomFormat());
  }, 1000);
});

var prependZero = function(num) {
  return (num < 10)? ("0" + num) : num;
}

Date.prototype.toCustomFormat = function() {
  var h = this.getHours(),
      h_12hr = (h % 12),
      hh = prependZero((h_12hr == 0)? 12 : h_12hr),
      mm = prependZero(this.getMinutes()),
      ss = prependZero(this.getSeconds()),
      a  = (h >= 12)? "pm" : "am";
  return (this.toString("MMM dd, yyyy") + " " + hh + ":" + mm + ":" + ss + " " + a);
}
