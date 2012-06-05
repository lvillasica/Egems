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

  it 'should get minutes late'
  it 'should get total hours'

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
end
