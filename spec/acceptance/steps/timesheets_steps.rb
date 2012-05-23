step 'I should see my timesheet entry for the day' do
  current_path.should == send("timein_path")
  follow_redirect!
  date_today = Time.now.beginning_of_day.localtime.strftime("%Y-%m-%d")
  save_and_open_page
  find("td", :visible => true).text.should == date_today
end

step 'I have timein, timeout entry for previous timesheet' do
  user = User.find_by_login("ldaplogin")
  user.timesheets.each {|t| t.destroy}
  date_yesterday = Time.now.beginning_of_day.yesterday
  time_yesterday = Time.now.yesterday
  timesheet_yesterday = user.timesheets.new(:date => date_yesterday,
                                            :time_in => time_yesterday,
                                            :time_out => time_yesterday)
  timesheet_yesterday.save
end

step 'I should have time in value for the current time' do
  user = User.find_by_login("ldaplogin")
  timein_val = user.timesheets.latest.last.time_in
  page.should have_content("#{timein_val.localtime.strftime("%Y-%m-%d")}")
end

step 'I have no invalid entries for the past days' do
  user = User.find_by_login("ldaplogin")
  user.timesheets.each(&:destroy)
end
