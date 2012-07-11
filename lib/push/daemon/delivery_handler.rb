module Push
  module Daemon
    class DeliveryHandler
      attr_reader :name
      STOP = 0x666

      def initialize(i)
        @name = "DeliveryHandler #{i}"
      end

      def start
        Thread.new do
          loop do
            break if @stop
            handle_next_notification
          end
        end
      end

      def stop
        @stop = true
        Push::Daemon.delivery_queue.push(STOP)
      end

      protected

      def handle_next_notification
        notification = Push::Daemon.delivery_queue.pop

        if notification == STOP
          return
        end

        begin
          connection = Push::Daemon.connection_pool.checkout(notification.use_connection)
          notification.deliver(connection)
        rescue StandardError => e
          Push::Daemon.logger.error(e)
        ensure
          Push::Daemon.connection_pool.checkin(connection)
          Push::Daemon.delivery_queue.notification_processed
        end
      end
    end
  end
end