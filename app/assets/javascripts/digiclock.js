$(function() {
  var prependZero = function(num) {
    return (num < 10)? ("0" + num) : num;
  }
  
  setInterval(function() {
    now = new Date();
    h = now.getHours();
    h_12hr = (h % 12);
    hh = prependZero((h_12hr == 0)? 12 : h_12hr);
    mm = prependZero(now.getMinutes());
    ss = prependZero(now.getSeconds());
    a = (h >= 12)? "pm" : "am";
    
    $('span#time').html(hh + ":" + mm + ":" + ss + " " + a);
  }, 1000);
});
