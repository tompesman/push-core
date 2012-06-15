module Push
  class Feedback < ActiveRecord::Base
    self.table_name = 'push_feedback'

    validates :device, :presence => true
    validates :failed_at, :presence => true
  end
end