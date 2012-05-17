step 'I should see my timesheet entry for the day' do
  page.should have_content("#{Date.today.beginning_of_day}")
end

step 'I have no time entries for today' do

end

step 'I have entries for today with latest timeout' do

end

step 'I should have time in with the current time' do

end
