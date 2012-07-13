jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()
  $("#main-nav .btn-navbar").click ->
    $("#main-nav .nav-collapse").collapse("toggle")
  $(".leaves-lnk").dropdown()
  $("#main-container .collapse").collapse()
  $(".accordion-toggle").click ->
  	$(this).parents(".accordion-group").children(".accordion-body").collapse("toggle")
