require 'spec_helper'

describe Timesheet do
  before :all do
    # clear all
    Timesheet.all.each(&:destroy)
  end

  context 'namescopes' do
    context 'latest' do
      before do
        @today = Time.now.beginning_of_day
      end

      it 'should get the latest timesheet' do
        Timecop.travel(@today) do
          Timesheet.create(:date => @today, :time_in => @today)
          Timesheet.latest.should_not be_empty
        end
      end
    end
  end

  describe :mins_late do
    before do
      @user = User.find_by_login('lvillasica')
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

  # TODO: incorporate shift_schedules
  context 'single timesheet' do
    context 'one within shift' do
      context 'undertime' do
        before do
          @today = Time.now.beginning_of_day
          Timecop.travel(@today) do
            @timesheet = Timesheet.create(:date => @today,
                                          :time_in => @today+9.hours,
                                          :time_out => @today+17.hours)
          end
        end

        it 'should update is_undertime and minutes_undertime' do
          @timesheet.is_undertime.should == 1
          @timesheet.minutes_undertime = 60
        end
      end
    end

    context 'one after shift' do
      it 'should be considered as AWOL'
    end
  end

  context 'multiple timesheets' do
    context 'multiple within shift' do
      context 'undertime' do
        before do
          @today = Time.now.beginning_of_day
          Timecop.travel(@today) do
            @timesheet1 = Timesheet.create(:date => @today,
                                           :time_in => @today+9.hours,
                                           :time_out => @today+15.hours)
            @timesheet2 = Timesheet.create(:date => @today,
                                           :time_in => @today+16.hours,
                                           :time_out => @today+17.hours)
          end
        end

        it 'should set is_undertime & minutes_undertime of previous timesheet/s to 0' do
          @timesheet1.is_undertime.should == 0
          @timesheet1.is_undertime.should == 0
        end

        it 'should update is_undertime & minutes_undertime of last timesheet' do
          @timesheet2.is_undertime.should == 1
          @timesheet2.minutes_undertime == 60
        end
      end
    end

    context 'one within shift and one after shift' do
      context 'undertime' do
        before do
          @today = Time.now.beginning_of_day
          Timecop.travel(@today) do
            @timesheet1 = Timesheet.create(:date => @today,
                                           :time_in => @today+9.hours,
                                           :time_out => @today+17.hours)
            @timesheet2 = Timesheet.create(:date => @today,
                                           :time_in => @today+18.hours,
                                           :time_out => @today+20.hours)
          end
        end

        it 'should update is_undertime & minutes_undertime of first timesheet' do
          @timesheet1.is_undertime.should == 1
          @timesheet1.minutes_undertime.should == 60
        end
      end
    end
  end
  
  describe :is_within_shift? do
    context 'when entry is within shift schedule' do
      it 'should return true'
    end
    
    context 'when entry is beyond shift schedule' do
      it 'should return false'
    end
    
    context 'when entry falls on weekend or holiday' do
      it 'should return false'
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
