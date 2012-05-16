step 'I should see my timesheet entry for the day' do
  page.should have_content("#{Date.today.beginning_of_day}")
end
