module Push
  module Daemon
    class DeliveryHandler
      attr_reader :name
      EXIT = :exit

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
      end

      def wakeup
        @queue.push(EXIT) if @thread
      end

      def wait
        @thread.join if @thread
      end

      protected

      def handle_next_notification
        notification = @queue.pop
        return if notification == EXIT

        begin
          connection = @connection_pool.checkout(notification, name)
          notification.deliver(connection)
        rescue DeliveryError => e
          Push.logger.error(e, {:error_notification => e.notify})
        rescue StandardError => e
          Push.logger.error(e)
        ensure
          @connection_pool.checkin(connection) if connection
        end
      end
    end
  end
end