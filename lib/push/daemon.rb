require 'thread'
require 'push/daemon/interruptible_sleep'
require 'push/daemon/delivery_error'
require 'push/daemon/disconnection_error'
require 'push/daemon/connection_pool'
require 'push/daemon/database_reconnectable'
require 'push/daemon/delivery_queue'
require 'push/daemon/delivery_handler'
require 'push/daemon/feedback'
require 'push/daemon/feedback/feedback_feeder'
require 'push/daemon/feedback/feedback_handler'
require 'push/daemon/feeder'
require 'push/daemon/logger'
require 'push/daemon/app'

module Push
  module Daemon
    class << self
      attr_accessor :logger, :config
    end

    def self.start(config)
      self.config = config
      self.logger = Logger.new(:foreground => config.foreground, :error_notification => config.error_notification)
      setup_signal_hooks
      daemonize unless config.foreground
      write_pid_file

      App.load
      App.start
      Feedback.load(config)
      Feedback.start
      rescale_poolsize(App.database_connections + Feedback.database_connections)

      logger.info('[Daemon] Ready')
      Feeder.start(config)
    end

    protected

    def self.rescale_poolsize(size)
      h = ActiveRecord::Base.connection_config
      # 1 feeder + providers
      h[:pool] = 1 + size

      # save the adjustments in the configuration
      ActiveRecord::Base.configurations[ENV['RAILS_ENV']] = h

      # apply new configuration
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.establish_connection(h)

      logger.info("[Daemon] Rescaled ActiveRecord ConnectionPool size to #{size}")
    end

    def self.setup_signal_hooks
      @shutting_down = false

      ['SIGINT', 'SIGTERM'].each do |signal|
        Signal.trap(signal) do
          handle_shutdown_signal
        end
      end
    end

    def self.handle_shutdown_signal
      exit 1 if @shutting_down
      @shutting_down = true
      shutdown
    end

    def self.shutdown
      print "\nShutting down..."
      Feeder.stop
      Feedback.stop
      App.stop

      while Thread.list.count > 1
        sleep 0.1
        print "."
      end
      print "\n"
      delete_pid_file
    end

    def self.daemonize
      exit if pid = fork
      Process.setsid
      exit if pid = fork

      Dir.chdir '/'
      File.umask 0000

      STDIN.reopen '/dev/null'
      STDOUT.reopen '/dev/null', 'a'
      STDERR.reopen STDOUT
    end

    def self.write_pid_file
      if !config[:pid_file].blank?
        begin
          File.open(configuration[:pid_file], 'w') do |f|
            f.puts $$
          end
        rescue SystemCallError => e
          logger.error("Failed to write PID to '#{config[:pid_file]}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = config[:pid_file]
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end
  end
end