module Push
  module Daemon
    class DeliveryHandler
      attr_reader :name

      def initialize(queue, connection_pool, name)
        @queue = queue
        @connection_pool = connection_pool
        @name = "DeliveryHandler #{name}"
      end

      def start
        @thread = Thread.new do
          loop do
            break if @stop
            handle_next_notification
          end
        end
      end

      def stop
        @stop = true
        @queue.wakeup(@thread)
      end

      protected

      def handle_next_notification
        begin
          notification = @queue.pop
        rescue DeliveryQueue::WakeupError
          return
        end

        begin
          connection = @connection_pool.checkout(notification.use_connection)
          notification.deliver(connection)
        rescue DeliveryError => e
          Push::Daemon.logger.error(e, {:error_notification => e.notify})
        rescue StandardError => e
          Push::Daemon.logger.error(e)
        ensure
          @connection_pool.checkin(connection)
          @queue.notification_processed
        end
      end
    end
  end
end