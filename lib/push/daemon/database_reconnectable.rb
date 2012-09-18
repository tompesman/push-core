module Push
  module Daemon
    module DatabaseReconnectable
      def adaptor_errors
        errors = [ActiveRecord::StatementInvalid]
        errors << PGError if defined?(PGError)
        errors << Mysql2::Error if defined?(Mysql2)
        errors
      end

      def with_database_reconnect_and_retry(name)
        begin
          yield
        rescue *adaptor_errors => e
          Push::Daemon.logger.error(e)
          database_connection_lost(name)
          retry
        end
      end

      def database_connection_lost(name)
        Push::Daemon.logger.warn("[#{name}] Lost connection to database, reconnecting...")
        attempts = 0
        loop do
          begin
            Push::Daemon.logger.warn("[#{name}] Attempt #{attempts += 1}")
            reconnect_database
            check_database_is_connected
            break
          rescue *adaptor_errors => e
            Push::Daemon.logger.error(e, :airbrake_notify => false)
            sleep_to_avoid_thrashing
          end
        end
        Push::Daemon.logger.warn("[#{name}] Database reconnected")
      end

      def reconnect_database
        ActiveRecord::Base.clear_all_connections!
        ActiveRecord::Base.establish_connection
      end

      def check_database_is_connected
        # Simply asking the adapter for the connection state is not sufficient.
        Push::Message.count
      end

      def sleep_to_avoid_thrashing
        sleep 2
      end
    end
  end
end