step 'I go to the :path page' do |path|
  visit send("#{path}_path")
end

step 'I fill in the following:' do |table|
  table.hashes.each do |hash|
    fill_in hash['field'], :with => hash['value']
  end
end

step 'I press :button' do |button|
  click_on button
end

step 'I am on the :path page' do |path|
  current_path.should == send("#{path}_path")
end

step 'I sign in as :username with password :password' do |name, pass|
  @user = User.find_by_login(name) || User.create(login: name)
  visit "/"
  fill_in "user_login", :with => name
  fill_in "user_password", :with => pass
  step "I press 'Sign in'"
end

step 'I time in as :username with password :password' do |name, pass|
  @user = User.find_by_login(name) || User.create(login: name)
  visit "/"
  fill_in "user_login", :with => name
  fill_in "user_password", :with => pass
  Timecop.freeze(Time.now)
  step "I press 'Time in'"
end

step 'I should be on the :path page' do |path|
  current_path.should == send("#{path}_path")
end

step 'I should not be on the :path page' do | path|
  current_path.should_not == send("#{path}_path")
end

step 'I should see the :name :element' do |name, element|
  case element
  when 'button'
    page.should have_button(name)
  when 'text'
    page.should have_content(name)
  when 'link'
    page.should have_link(name)
  end
end

step 'I should not see :name :element' do |name, element|
  case element
  when 'button'
    page.should have_no_button(name)
  when 'text'
    page.should have_no_content(name)
  when 'link'
    page.should have_no_link(name)
  end
end
