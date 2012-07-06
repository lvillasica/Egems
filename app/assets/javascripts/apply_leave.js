
/****************************************************
  CLIENT SIDE VALIDATIONS FOR LEAVE APPLICATION FORM
*****************************************************/

$(function () {

  var newLeaveForm = $('#new_leave_detail'),
      leaveTypeSelect = $('#leave_detail_leave_type'),
      leaveDateFld = $('#leave_detail_leave_date'),
      endDateFld = $('#leave_detail_end_date'),
      leaveUnitFld = $('#leave_detail_leave_unit'),
      startDate = null,
      endDate = null,
      maxDate = null,
      minDate = null;
  
  var setFldsForLeaveType = function ( leaveType ) {
    switch ( leaveType ) {
    case 'Vacation Leave':
      minDate = new Date().add(1).day();
      maxDate = new Date().getEndOfYear();
      setDateFldVal(leaveDateFld, minDate);
      setDateFldVal(endDateFld, minDate);
      break;
    case "Sick Leave": case "Emergency Leave":
      minDate = new Date().getStartOfYear();
      maxDate = new Date();
      setDateFldVal(leaveDateFld, maxDate);
      setDateFldVal(endDateFld, maxDate);
      break;
    default:
      minDate = new Date().getStartOfYear();
      maxDate = new Date().getEndOfYear();
      setDateFldVal(leaveDateFld, new Date());
      setDateFldVal(endDateFld, new Date());
    }

    dateSelector('leave_detail_leave_date', {minDate: minDate, maxDate: maxDate});
    leaveDateFld.trigger('change');
  }
  
  var setDateFldVal = function ( dateFld, newDateVal ) {
    var fldDateVal = Date.parse(dateFld.val()) || new Date();
    if ( fldDateVal >= minDate && fldDateVal <= maxDate ) {
      dateFld.val(fldDateVal.toString("yyyy-MM-dd"));
    } else {
      dateFld.val(newDateVal.toString("yyyy-MM-dd"));
    }
  }
  
  var setNoOfDays = function () {
    var offset = 1; // 1 day offset value
    if ( checkIfHalfDay() == true ) offset = 0.5;
    setDates();
    var diff = (endDate - startDate) / 1000 / 60 / 60 / 24;
    var leaveUnit = parseFloat((diff + offset) - nonWorkingDays().length).toFixed(1)
    leaveUnitFld.val((leaveUnit >= 0)? leaveUnit : parseFloat(0.0).toFixed(1));
  }
  
  var nonWorkingDays = function () {
    var current = startDate.clone(),
        result = new Array();
    
    while ( current <= endDate ) {
      var tmpDay = current.clone();
      
      for ( var i = 0; i < rb.dayOffs.length; i++ ) {
        var from = Date.parse(rb.dayOffs[i].from),
            to = Date.parse(rb.dayOffs[i].to),
            days = rb.dayOffs[i].days;
        if ( tmpDay >= from && tmpDay <= to && $.inArray(tmpDay.getDay(), days) != -1 ) {
          result.push(tmpDay);
        }
      }
      
      for ( var i = 0; i < rb.holidays.length; i++ ) {
        var holidayDate = new Date(rb.holidays[i].date);
        if ( (tmpDay.getDateOnly() - holidayDate.getDateOnly()) == 0 ) {
          if ( $.inArray(tmpDay, result) == -1 ) result.push(tmpDay);
        }
      }
      
      current.addDays(1);
    }
    
    return result;
  }
  
  var setDates = function () {
    startDate = Date.parse(leaveDateFld.val());
    endDate = Date.parse(endDateFld.val());
  }
  
  var checkIfHalfDay = function () {
    if ( $("#new_leave_detail input[name='leave_detail[period]']:checked").length > 0 ) {
      $('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', true);
      return true;
    }
  }
  
  var validateDateFld = function ( field ) {
    if ( Date.parse(field.val()) == null ) {
      field.closest('.control-group').addClass('error');
      return false;
    } else {
      field.closest('.control-group').removeClass('error');
      return true;
    }
  }
  
  var setListeners = function () {
    // set fields' listeners ---------------------------------------------------
    leaveTypeSelect.change ( function () {
      setFldsForLeaveType($(this).val());
      setNoOfDays();
    });
    
    leaveDateFld.change ( function () {
      setDates();
      if ( maxDate != "" && startDate > maxDate )
        $(this).val(maxDate.toString("yyyy-MM-dd"));
      if ( minDate != "" && startDate < minDate )
        $(this).val(minDate.toString("yyyy-MM-dd"));
      if ( startDate === endDate || startDate > endDate ) {
        endDateFld.val($(this).val());
      }
      dateSelector('leave_detail_end_date', {minDate: Date.parse($(this).val()), maxDate: maxDate});
      if ( checkIfHalfDay() == true ) {
        endDateFld.val(leaveDateFld.val());
      }
      if ( validateDateFld($(this)) == true ) endDateFld.trigger('change');
    });
    
    endDateFld.change ( function () {
      setDates();
      if ( maxDate != "" && endDate > maxDate )
        $(this).val( maxDate.toString("yyyy-MM-dd") );
      if ( checkIfHalfDay() == true || startDate > endDate )
        $(this).val(leaveDateFld.val());
      if ( validateDateFld($(this)) == true ) setNoOfDays();
    });
    
    leaveUnitFld.change ( function () {
      setNoOfDays();
    });
    
    $("#new_leave_detail input[name='leave_detail[period]']").change ( function () {
      $('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', true);
      endDateFld.val(leaveDateFld.val()).trigger('change');
    });
    
    $('#radio-reset-btn').click( function () {
      $("#new_leave_detail input[name='leave_detail[period]']").attr('checked', false);
      $('#leave_detail_end_date').next('.ui-datepicker-trigger').attr('disabled', false);
      setNoOfDays();
      return false;
    });
    // -------------------------------------------------------------------------
  }
  
  // if leave form is already loaded,
  if ( newLeaveForm.length > 0 ) {
    // start validations -------------------------------------------------------
    setListeners();
    setFldsForLeaveType(leaveTypeSelect.val());
    setNoOfDays();
    checkIfHalfDay();
    //--------------------------------------------------------------------------
  }
  
});

Date.prototype.getStartOfYear = function () {
  var year = this.getFullYear();
  return new Date(year, 0, 1);
}

Date.prototype.getEndOfYear = function () {
  var year = this.getFullYear();
  return new Date(year, 11, 31);
}

Date.prototype.getDateOnly = function () {
  var year = this.getFullYear(),
      mon  = this.getMonth(),
      day  = this.getDate();
  return new Date(year, mon, day);
}
