jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()
  $(".btn-navbar").click ->
    $(".nav-collapse").collapse("toggle")
  $(".leaves-lnk").dropdown()
  $(".collapse").collapse("hide")
  $(".accordion-toggle").click ->
  	$(this).parents(".accordion-group").children(".accordion-body").collapse("toggle")
