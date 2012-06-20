require 'spec_helper'

describe Timesheet do
  before :all do
    # clear all
    Timesheet.all.each(&:destroy)
    ShiftSchedule.all.each(&:destroy)

    @monday = Time.now.monday
    @shift_schedule = ShiftSchedule.create(:name => 'Regular')
    @shift_schedule_detail = @shift_schedule.shift_schedule_details.create(
                                            :day_of_week => @monday.wday,
                                            :am_time_start => (@monday + 8.hours) + 8.hours,
                                            :am_time_duration => 240,
                                            :am_time_allowance => 120,
                                            :pm_time_start => (@monday + 13.hours) + 8.hours,
                                            :pm_time_duration => 240,
                                            :pm_time_allowance => 120)

    @employee = Employee.create(:full_name => 'test subject',
                               :shift_schedule_id => @shift_schedule.id)
    shift = @shift_schedule_detail
    t_in = shift.am_time_start + shift.am_time_allowance.minutes
    @max_time_in = Time.local(@monday.year, @monday.month, @monday.day, t_in.hour, t_in.min)
    t_out = shift.pm_time_start + shift.pm_time_duration.minutes + shift.pm_time_allowance.minutes
    @max_time_out = Time.local(@monday.year, @monday.month, @monday.day, t_out.hour, t_out.min)
  end

  context 'namescopes' do
    context 'latest' do
      it 'should get the latest timesheet' do
        Timecop.travel(@monday) do
          @employee.timesheets.create(:date => @monday, :time_in => @max_time_in)
          @employee.timesheets.latest.should_not be_empty
        end
      end
    end
  end

  describe :mins_late do
    before do
      @user = User.find_by_login('lvillasica').employee
      @user.timesheets.each(&:destroy)
    end

    context 'when timein is beyond maximum considerable timein' do
      it 'should get the total minutes late' do
        time = Time.parse("10:02am")
        Timecop.return
        Timecop.freeze(time)
        Timesheet.time_in!(@user)
        @user.timesheets.latest.last.mins_late.should_not be_zero
      end
    end

    context 'when timein is within earliest and maximum considerable timein' do
      it 'should return 0' do
        time = Time.parse("9:40am")
        Timecop.return
        Timecop.freeze(time)
        Timesheet.time_in!(@user)
        @user.timesheets.latest.last.mins_late.should be_zero
      end
    end
  end

  context '#single timesheet' do
    context ':one within shift' do
      before do
        Timecop.travel(@monday) do
          @timesheet = @employee.timesheets.create(:date => @monday, :time_in => @max_time_in)
        end
      end

      context 'where timeout is before end of shift' do
        it 'should have undertime and no excess' do
          @timesheet.time_out = @max_time_out - 1.hour
          @timesheet.save
          @timesheet.minutes_undertime = 60
          @timesheet.minutes_excess = 0
        end
      end

      context 'where timeout is after end of shift' do
        it 'should have excess and no undertime' do
          @timesheet.time_out = @max_time_out + 1.hour
          @timesheet.save
          @timesheet.minutes_undertime = 0
          @timesheet.minutes_excess = 60
        end
      end
    end

    context ':one after shift' do
      before do
        Timecop.travel(@monday) do
          @timesheet = @employee.timesheets.create(:date => @monday, :time_in => @max_time_out + 1.hour)
        end
      end
      it 'should be considered as AWOL' do
        @timesheet.time_out = @timesheet.time_in + 2.hours
        @timesheet.save
        @timesheet.minutes_undertime = 0
        @timesheet.minutes_excess = 0
      end
    end
  end

  context '#multiple timesheets' do
    context ':multiple within shift' do
      before do
        Timecop.travel(@monday) do
          @timesheet1 = @employee.timesheets.create(:date => @monday, :time_in => @max_time_in,
                                         :time_out => @max_time_out - 3.hours)
          @timesheet2 = @employee.timesheets.create(:date => @monday, :time_in => @timesheet1.time_out + 1.hour)
        end
      end

      context 'where timeout is before end of shift' do
        it 'should have undertime and no excess' do
          @timesheet2.time_out = @max_time_out - 1.hour
          @timesheet2.save
          @timesheet1.minutes_undertime = 0
          @timesheet1.minutes_excess = 0
          @timesheet2.minutes_undertime = 60
          @timesheet2.minutes_excess = 0
        end
      end

      context 'where timeout is after end of shift' do
        it 'should have excess and no undertime' do
          @timesheet2.time_out = @max_time_out + 1.hour
          @timesheet2.save
          @timesheet1.minutes_undertime = 0
          @timesheet1.minutes_excess = 0
          @timesheet2.minutes_undertime = 0
          @timesheet2.minutes_excess = 60
        end
      end
    end

    context ':one within shift and one after shift' do
      before do
        @monday = Time.now.monday
        Timecop.travel(@monday) do
          @timesheet1 = @employee.timesheets.create(:date => @monday, :time_in => @max_time_in)
        end
      end

      context 'where first timesheet timeout is before end of shift' do
        it 'should have undertime and no excess' do
          @timesheet1.time_out = @max_time_out - 1.hour
          @timesheet1.save
          @timesheet2 = @employee.timesheets.create(:date => @monday, :time_in => @max_time_out + 1.hour)
          @timesheet2.time_out = @timesheet2.time_in + 1.hour
          @timesheet2.save
          @timesheet1.minutes_undertime = 0
          @timesheet1.minutes_excess = 0
          @timesheet2.minutes_undertime = 60
          @timesheet2.minutes_excess = 0
        end
      end

      context 'where first timesheet timeout is after end of shift' do
        it 'should have undertime and no excess' do
          @timesheet1.time_out = @max_time_out + 1.hour
          @timesheet1.save
          @timesheet2 = @employee.timesheets.create(:date => @monday, :time_in => @timesheet1.time_out + 1.hour)
          @timesheet2.time_out = @timesheet2.time_in + 1.hour
          @timesheet2.save
          @timesheet1.minutes_undertime = 0
          @timesheet1.minutes_excess = 60
          @timesheet2.minutes_undertime = 0
          @timesheet2.minutes_excess = 60
        end
      end
    end
  end

  describe :is_within_shift? do
    context 'when entry is within shift schedule' do
      it 'should return true' do
        Timecop.travel(@monday) do
          timesheet = @employee.timesheets.create(:date => @monday, :time_in => @max_time_in)
          timesheet.time_out = @max_time_out
          timesheet.save
          timesheet.is_within_shift? == true
        end
      end
    end

    context 'when entry is beyond shift schedule' do
      it 'should return false' do
        Timecop.travel(@monday) do
          timesheet = @employee.timesheets.create(:date => @monday, :time_in => @max_time_out + 1.minute)
          timesheet.time_out = timesheet.time_in + 1.hour
          timesheet.save
          timesheet.is_within_shift? == false
        end
      end
    end

    context 'when entry falls on weekend or holiday' do
      it 'should return false' do
        sunday = Time.now.sunday.beginning_of_day
        Timecop.travel(sunday) do
          @shift_schedule_detail = @shift_schedule.shift_schedule_details.create(
                                                  :day_of_week => sunday)
          timesheet = @employee.timesheets.create(:date => sunday, :time_in => sunday + 9.hours)
          timesheet.time_out = timesheet.time_in + 4.hours
          timesheet.save
          timesheet.is_within_shift? == false
        end
      end
    end
  end

  describe :weekend? do
    context 'when entry date falls on a weekend' do
      it 'should return true'
    end

    context 'when entry date did not fall on a weekend' do
      it 'should return false'
    end
  end

  describe :holiday? do
    context 'when entry date is a holiday' do
      it 'should return true'
    end

    context 'when entry date is not a holiday' do
      it 'should return false'
    end
  end

  describe :total_hours do
    it 'should get total hours'
  end
end
