module Push
  module Daemon
    class Feeder
      extend DatabaseReconnectable
      extend InterruptibleSleep

      def self.name
        "Feeder"
      end

      def self.start(foreground)
        reconnect_database unless foreground

        loop do
          break if @stop
          enqueue_notifications
          interruptible_sleep Push::Daemon.configuration[:poll]
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
      end

      protected

      def self.enqueue_notifications
        begin
          with_database_reconnect_and_retry(name) do
            if Push::Daemon.delivery_queue.notifications_processed?
              Push::Message.ready_for_delivery.find_each do |notification|
                Push::Daemon.delivery_queue.push(notification)
              end
            end
          end
        rescue StandardError => e
          Push::Daemon.logger.error(e)
        end
      end
    end
  end
end