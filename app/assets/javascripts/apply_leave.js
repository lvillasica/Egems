
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
      minDate = null;
  
  var setFldsForLeaveType = function ( leaveType ) {
    if ( leaveType == 'Vacation Leave' ) {
      minDate = new Date().add(1).day();
    } else {
      minDate = new Date();
    }
    
    if ( startDate != null && startDate > minDate ) {
      leaveDateFld.val(startDate.toString("yyyy-MM-dd"));
    } else {
      leaveDateFld.val(minDate.toString("yyyy-MM-dd"));
      endDateFld.val((endDate != null)? endDate.toString("yyyy-MM-dd") : leaveDateFld.val());
    }

    dateSelector('leave_detail_leave_date', {minDate: minDate});
    leaveDateFld.trigger('change');
  }
  
  var setNoOfDays = function () {
    var offset = 1; // 1 day offset value
    if ( checkIfHalfDay() == true ) offset = 0.5;
    setDates();
    var diff = (endDate - startDate) / 1000 / 60 / 60 / 24;
    leaveUnitFld.val(parseFloat(diff + offset).toFixed(1));
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
  
  // if leave form is already loaded,
  if ( newLeaveForm != undefined ) {
  
    // set fields' listeners ---------------------------------------------------
    leaveTypeSelect.change ( function () {
      setFldsForLeaveType($(this).val());
      setNoOfDays();
    });
    
    leaveDateFld.change ( function () {
      setDates();
      if ( startDate === endDate || startDate > endDate ) {
        endDateFld.val($(this).val());
      }
      dateSelector('leave_detail_end_date', {minDate: Date.parse($(this).val())});
      if ( checkIfHalfDay() == true ) {
        endDateFld.val(leaveDateFld.val());
      }
      if ( validateDateFld($(this)) == true ) endDateFld.trigger('change');
    });
    
    endDateFld.change ( function () {
      setDates();
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
    
    // start validations -------------------------------------------------------
    setFldsForLeaveType(leaveTypeSelect.val());
    setNoOfDays();
    checkIfHalfDay();
    //--------------------------------------------------------------------------
  }
  
});

