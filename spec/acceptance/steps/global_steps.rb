step 'I go to the :path' do |path|
  visit path
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
  current_path.should != send("#{path}_path")
end


