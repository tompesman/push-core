require 'active_record'
require 'active_record/errors'
require 'push/daemon/database_reconnectable'
module Push
  class Message < ActiveRecord::Base
    include Push::Daemon::DatabaseReconnectable
    self.table_name = "push_messages"

    validates :device, :presence => true

    scope :ready_for_delivery, lambda { where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)', false, false, Time.now) }

    def deliver(connection)
      begin
        connection.write(self.to_message)
        check_for_error(connection)

        # this makes no sense in the rails environment, but it does in the daemon
        with_database_reconnect_and_retry(connection.name) do
          self.delivered = true
          self.delivered_at = Time.now
          self.save!(:validate => false)
        end

        Push::Daemon.logger.info("Message #{id} delivered to #{device}")
      rescue Push::DeliveryError, Push::DisconnectionError => error
        handle_delivery_error(error, connection)
        raise
      end
    end

    private

    def handle_delivery_error(error, connection)
      # this code makes no sense in the rails environment, but it does in the daemon
      with_database_reconnect_and_retry(connection.name) do
        self.delivered = false
        self.delivered_at = nil
        self.failed = true
        self.failed_at = Time.now
        self.error_code = error.code
        self.error_description = error.description
        self.save!(:validate => false)
      end
    end
  end
end