require 'spec_helper'

describe Timesheet do
  context 'namescopes' do
    context 'latest' do
      before do
        @yesterday = (Time.now - 2.days).utc
        @today     = Time.now.utc
      end

      it 'should get the latest timesheet' do
        Timecop.travel(@today) do
          Timesheet.create(:date => @today, :time_in => @today)
          Timesheet.latest.should_not be_empty
        end
      end
    end
  end
end
