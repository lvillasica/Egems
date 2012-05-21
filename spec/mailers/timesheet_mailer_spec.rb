require "spec_helper"

describe TimesheetMailer do

  context 'invalid_timesheet' do
    before do
      @user      = mock('user', :email      => 'egems-user1@example.com',
                                :first_name => 'user1')
      @timesheet = mock('timesheet', :timeine => 1.day.ago,
                                     :timeout => nil)
    end

    it 'should send email to user' do
      mail = TimesheetMailer.invalid_timesheet(@user, @timesheet).deliver
      mail.to.should == [@user.email]
    end

    it 'should contain user first name on the salutation' do
      mail = TimesheetMailer.invalid_timesheet(@user, @timesheet).deliver
      mail.body.should =~ /#{@user.first_name}/
    end

    it 'should use the default layout' do
      mail = TimesheetMailer.invalid_timesheet(@user, @timesheet).deliver
      mail.body.should =~ /logo\.png/
    end
  end

end
