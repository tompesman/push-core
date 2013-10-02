module Push
  module Daemon
    class Feeder
      extend DatabaseReconnectable

      def self.name
        "Feeder"
      end

      def self.start
        @interruptible_sleeper = InterruptibleSleep.new(Push.config.push_poll)
        reconnect_database unless Push.config.foreground

        loop do
          enqueue_notifications
          break if @stop or Push.config.single_run
          @interruptible_sleeper.sleep
        end
        Push.logger.info "[#{name}] stopped"
      end

      def self.stop
        Push.logger.info "[#{name}] stopping"
        @stop = true
        @interrupt_sleeper.interrupt_sleep if @interrupt_sleeper
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
          Push.logger.error(e)
        end
      end
    end
  end
end