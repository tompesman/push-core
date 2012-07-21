module Push
  class Feedback < ActiveRecord::Base
    include Push::Daemon::DatabaseReconnectable
    self.table_name = 'push_feedback'

    scope :ready_for_followup, where(:processed => false)
    validates :app, :presence => true
    validates :device, :presence => true
    validates :follow_up, :presence => true
    validates :failed_at, :presence => true

    def is_processed(name)
      with_database_reconnect_and_retry(name) do
        self.processed = true
        self.processed_at = Time.now
        self.save
      end
    end
  end
end