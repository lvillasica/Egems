# givens
step 'I have valid time entries' do
  @user.timesheets.each(&:destroy)
  today = Time.now
  yesterday = today.yesterday
  Timecop.freeze(today)
  @user.timesheets.create(:date => today, :time_in => today, :time_out => today)
  @user.timesheets.create(:date => yesterday, :time_in => yesterday, :time_out => yesterday)
end

step 'I have no invalid time entries' do
  @user.timesheets.each(&:destroy)
end

step 'I have not timeout yesterday' do
  Timecop.return
  @user.timesheets.each(&:destroy)
  yesterday = Time.now.yesterday
  @previous = yesterday
  @user.timesheets.create(:date => yesterday, :time_in => yesterday, :time_out => nil)
end

step 'I have timein today but no timeout' do
  @user.timesheets.each(&:destroy)
  today = Time.now
  Timecop.freeze(today)
  @user.timesheets.create(:date => today, :time_in => today, :time_out => nil)
end

# whens
step 'I submit missing timeout' do |day|
  timesheet = @user.timesheets.first(:select => :date, :order => 'date desc, created_on desc')
  date = timesheet.date.localtime
  now = Time.now
  time = Time.local(date.year, date.month, date.day, now.hour, now.min, 0)
  Timecop.travel(time) do
    fill_in 'timeout_hour', :with => time.strftime("%l")
    fill_in 'timeout_min', :with => time.min
    select time.strftime("%p"), :from => 'timeout_meridian'
    fill_in 'timeout_date', :with => date.strftime("%Y-%m-%d")
  end
  Timecop.freeze(time)
  step "I press 'Time out'"
end

# thens
step 'I should see my time entry today' do
  step "I go to the 'timesheets' page"
  Timecop.travel(Time.now) do
    page.should have_content(Time.now.strftime("%Y-%m-%d"))
    page.should have_content(Time.now.strftime("%I:%M:%S %p %Y-%m-%d"))
  end
  Timecop.return
end

step 'I should be prompted to timeout' do
  date = @previous || Time.now
  page.should have_content(date.strftime("%Y-%m-%d"))
  page.should have_field("timeout_date")
  page.should have_field("timeout_hour")
  page.should have_field("timeout_min")
  page.should have_select("timeout_meridian")
end

step 'I should see my timeout from the previous day' do
  step "I go to the 'timesheets' page"
  # frozen time from step 'I submit missing timeout'
  date = Time.now
  Timecop.return
  Timecop.travel(date) do
    prev_link = date.yesterday.strftime("%a")
    page.should have_content(date.strftime("%Y-%m-%d"))
    step "I press '#{prev_link}'"
    page.should have_content(date.strftime("%I:%M:%S %p %Y-%m-%d"))
  end
end
