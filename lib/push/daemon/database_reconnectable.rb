module Push
  module Daemon
    module DatabaseReconnectable
      def adaptor_errors
        errors = [ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished]
        if defined?(::PG::Error)
          errors << ::PG::Error
        elsif defined?(::PGError)
          errors << ::PGError
        end
        errors << ::Mysql2::Error if defined?(::Mysql2)
        errors
      end

      def with_database_reconnect_and_retry(name)
        begin
          yield
        rescue *adaptor_errors => e
          Push.logger.error(e)
          database_connection_lost(name)
          retry
        end
      end

      def database_connection_lost(name)
        Push.logger.warn("[#{name}] Lost connection to database, reconnecting...")
        attempts = 0
        loop do
          begin
            Push.logger.warn("[#{name}] Attempt #{attempts += 1}")
            reconnect_database
            check_database_is_connected
            break
          rescue *adaptor_errors => e
            Push.logger.error(e, :error_notification => false)
            sleep_to_avoid_thrashing
          end
        end
        Push.logger.warn("[#{name}] Database reconnected")
      end

      def reconnect_database
        begin
          ActiveRecord::Base.clear_all_connections!
        rescue
          Push.logger.error("ActiveRecord::Base.clear_all_connections! failed")
        ensure
          ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ENV['RAILS_ENV']])
        end
      end

      def check_database_is_connected
        # Simply asking the adapter for the connection state is not sufficient.
        Push::Message.count
      end

      def sleep_to_avoid_thrashing
        sleep 2
      end

      def self.rescale_poolsize(name, size)
        h = ActiveRecord::Base.connection_config
        # 1 feeder + providers
        h[:pool] = 1 + size

        # save the adjustments in the configuration
        ActiveRecord::Base.configurations[ENV['RAILS_ENV']] = h

        # apply new configuration
        ActiveRecord::Base.clear_all_connections!
        ActiveRecord::Base.establish_connection(h)

        Push.logger.info("[#{name}] Rescaled ActiveRecord ConnectionPool size to #{size}")
      end
    end
  end
end