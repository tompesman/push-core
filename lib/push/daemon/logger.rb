module Push
  module Daemon
    class Logger
      def initialize(options)
        @options = options
        open_log unless @options[:foreground]
      end

      def info(msg)
        log(:info, msg)
      end

      def error(msg, options = {})
        airbrake_notify(msg) if notify_via_airbrake?(msg, options)
        log(:error, msg, 'ERROR')
      end

      def warn(msg)
        log(:warn, msg, 'WARNING')
      end

      private

      def log(where, msg, prefix = nil)
        if msg.is_a?(Exception)
          msg = "#{msg.class.name}, #{msg.message}: #{msg.backtrace.join("\n")}"
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

      def airbrake_notify(e)
        return unless @options[:airbrake_notify] == true

        if defined?(Airbrake)
          Airbrake.notify_or_ignore(e)
        elsif defined?(HoptoadNotifier)
          HoptoadNotifier.notify_or_ignore(e)
        end
      end

      def notify_via_airbrake?(msg, options)
        msg.is_a?(Exception) && options[:airbrake_notify] != false
      end
    end
  end
end