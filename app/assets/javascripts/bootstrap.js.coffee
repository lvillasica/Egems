jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()
  $(".btn-navbar").click ->
    $(".nav-collapse").collapse("toggle")
  $(".leaves-lnk").dropdown()
  $(".collapse").collapse("hide")
  $(".acc-toggle").click ->
  	$(this).parents(".accordion-container").children(".collapse#leave").collapse("toggle")



