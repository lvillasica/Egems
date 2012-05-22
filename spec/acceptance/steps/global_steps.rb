step 'I go to the :path page' do |path|
  visit send("#{path}_path")
end

step 'I fill in the following:' do |table|
  table.hashes.each do |hash|
    fill_in hash['field'], :with => hash['value']
  end
end

step 'I press :button' do |button|
  click_button button
end

step 'I should be on the :path page' do |path|
  current_path.should == send("#{path}_path")
end

step 'I should not be on the :path page' do | path|
  current_path.should_not == send("#{path}_path")
end

step 'I should see :name :element' do |name, element|
  case element
  when 'button'
    page.should have_button("#{name}")
  when 'text'
    page.should have_content("#{name}")
  end
end

step 'I am logged in' do
  visit signin_path
  fill_in 'user_login', :with => 'ldaplogin'
  fill_in 'user_password', :with => 'ldappassword'
  click_button 'Sign in'
end

step 'I am on the :path page' do |path|
  current_path.should == send("#{path}_path")
end

step 'I am not authorized' do
  visit '/'
  fill_in "user_login", :with=>"invalid_login"
  fill_in "user_password", :with=>"invalid_pass"
  step "I press 'Sign in'"
  step "I should be on the 'signin' page"
end

step 'I am authorized' do
  step "I am logged in"
  step "I should be on the 'timesheets' page"
end

