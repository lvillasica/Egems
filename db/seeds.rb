require 'csv'
# Load the Employee List that is in csv format with headers
# (username, date_hired, status, regularization_date)
employee_list_csv_file = File.open(File.join(Rails.root, 'db/seed/employee_list.csv'), 'rb')
indx = 0

CSV.parse(employee_list_csv_file) do |row|
  indx +=1
  next if indx == 1 || row[0].blank?
  user = User.new(:login => row[0],
                  :employee_id => indx)
  user.save rescue puts "user was not saved: #{user.login} - index: #{indx}"
end
