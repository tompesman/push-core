module Push
  module Daemon
    class Logger
      def initialize(options)
        @options = options

        if @options[:foreground]
          STDOUT.sync = true
        else
          open_log
        end
      end

      def info(msg)
        log(:info, msg)
      end

      def error(msg, options = {})
        error_notification(msg, options)
        log(:error, msg, 'ERROR')
      end

      def warn(msg)
        log(:warn, msg, 'WARNING')
      end

      private

      def log(where, msg, prefix = nil)
        if msg.is_a?(Exception)
          msg = "#{msg.class.name}, #{msg.message}: #{msg.backtrace.join("\n") if msg.backtrace}"
        end

        formatted_msg = "[#{Time.now.to_s(:db)}] "
        formatted_msg << "[#{prefix}] " if prefix
        formatted_msg << msg

        if @options[:foreground]
          puts formatted_msg
        else
          @logger.send(where, formatted_msg)
        end
      end

      def open_log
        log_file = File.open(File.join(Rails.root, 'log', 'push.log'), 'w')
        log_file.sync = true
        @logger = ActiveSupport::BufferedLogger.new(log_file, Rails.logger.level)
        @logger.auto_flushing = Rails.logger.respond_to?(:auto_flushing) ? Rails.logger.auto_flushing : true
      end

      def error_notification(e, options)
        return unless do_error_notification?(e, options)

        if defined?(Airbrake)
          Airbrake.notify_or_ignore(e)
        elsif defined?(HoptoadNotifier)
          HoptoadNotifier.notify_or_ignore(e)
        elsif defined?(Bugsnag)
          Bugsnag.notify(e)
        end
      end

      def do_error_notification?(msg, options)
        @options[:error_notification] and options[:error_notification] != false and msg.is_a?(Exception)
      end
    end
  end
end