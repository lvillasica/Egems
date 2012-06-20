jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()
  $(".btn-navbar").click ->
    $(".nav-collapse").collapse("toggle")
  $(".leaves-lnk").dropdown()
