jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()
  $("#main-nav .btn-navbar").click ->
    $("#main-nav .nav-collapse").collapse("toggle")
  $("#leaves-lnk").dropdown()
  $("#overtimes-lnk").dropdown()
  $("#timesheets-lnk").dropdown()
  $("#hrmodule-lnk").dropdown()
  $("#main-container .collapse").collapse()
