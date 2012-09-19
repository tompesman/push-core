module Push
  module Daemon
    class Feeder
      extend DatabaseReconnectable
      extend InterruptibleSleep

      def self.name
        "Feeder"
      end

      def self.start(config)
        reconnect_database unless config.foreground

        loop do
          break if @stop
          enqueue_notifications
          interruptible_sleep config.push_poll
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
            ready_apps = Push::Daemon::App.ready
            Push::Message.ready_for_delivery.find_each do |notification|
              Push::Daemon::App.deliver(notification) if ready_apps.include?(notification.app)
            end
          end
        rescue StandardError => e
          Push::Daemon.logger.error(e)
        end
      end
    end
  end
end