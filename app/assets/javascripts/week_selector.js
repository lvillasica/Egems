$(function() {
  var startDate;
  var endDate;
  
  var selectCurrentWeek = function() {
    window.setTimeout(function () {
      $('#ui-datepicker-div').find('.ui-datepicker-current-day a').addClass('ui-state-active')
    }, 1);
  }
  
  var setCurrentWeek = function(elem, date, inst) {
    day = (date.getDay() == 0)? 6 : date.getDay() - 1;
    startDate = new Date(date.getFullYear(), date.getMonth(), date.getDate() - day);
    endDate = new Date(date.getFullYear(), date.getMonth(), date.getDate() - day + 6);
    var dateFormat = inst.settings.dateFormat || $.datepicker._defaults.dateFormat;
    var startWeek = $.datepicker.formatDate( dateFormat, startDate, inst.settings );
    var endWeek = $.datepicker.formatDate( dateFormat, endDate, inst.settings );
    elem.val(startWeek + ' to ' + endWeek);
  }
  
  $('#week-picker').datepicker( {
    showOtherMonths: true,
    selectOtherMonths: true,
    showOn: "button",
    buttonText: "<i class='icon-calendar'></i>",
    firstDay: 1,
    dateFormat: 'yy-mm-dd',
    onSelect: function(dateText, inst) {
      var date = $(this).datepicker('getDate');
      var href="/timesheets/" + date + "/week"
      setCurrentWeek($(this), date, inst);
      selectCurrentWeek();
      $("#week_tab").attr("href", "/timesheets/" + date + "/week").trigger('click');
    },
    beforeShow: function(input, inst) {
      var date = new Date($(input).val().split(" ")[0]);
      setCurrentWeek($(this), date, inst);
      selectCurrentWeek();
    },
    beforeShowDay: function(date) {
      var cssClass = '';
      if(date >= startDate && date <= endDate)
        cssClass = 'ui-datepicker-current-day';
      return [true, cssClass];
    },
    onChangeMonthYear: function(year, month, inst) {
      selectCurrentWeek();
    }
  });
  
  $('#ui-datepicker-div .ui-datepicker-calendar tr').live('mousemove', function() { $(this).find('td a').addClass('ui-state-hover'); });
  $('#ui-datepicker-div .ui-datepicker-calendar tr').live('mouseleave', function() { $(this).find('td a').removeClass('ui-state-hover'); });
  $('.ui-datepicker-trigger').addClass("btn");
});
