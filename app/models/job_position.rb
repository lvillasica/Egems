class JobPosition < ActiveRecord::Base
  has_many :employees, :foreign_key => :current_job_position_id
end

