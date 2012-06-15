require 'thread'
require 'push/daemon/builder'
require 'push/daemon/interruptible_sleep'
require 'push/daemon/delivery_error'
require 'push/daemon/disconnection_error'
require 'push/daemon/pool'
require 'push/daemon/connection_pool'
require 'push/daemon/database_reconnectable'
require 'push/daemon/delivery_queue'
require 'push/daemon/delivery_handler'
require 'push/daemon/delivery_handler_pool'
require 'push/daemon/feeder'
require 'push/daemon/logger'

module Push
  module Daemon
    class << self
      attr_accessor :logger, :configuration, :delivery_queue,
      :connection_pool, :delivery_handler_pool, :foreground, :providers
    end

    def self.start(environment, foreground)
      self.providers = []
      @foreground = foreground
      setup_signal_hooks

      require File.join(Rails.root, 'config', 'push', environment + '.rb')

      self.logger = Logger.new(:foreground => foreground, :airbrake_notify => configuration[:airbrake_notify])

      self.delivery_queue = DeliveryQueue.new

      daemonize unless foreground

      write_pid_file

      dbconnections = 0
      self.connection_pool = ConnectionPool.new
      self.providers.each do |provider|
        self.connection_pool.populate(provider)
        dbconnections += provider.totalconnections
      end

      rescale_poolsize(dbconnections)

      self.delivery_handler_pool = DeliveryHandlerPool.new(connection_pool.size)
      delivery_handler_pool.populate

      logger.info('[Daemon] Ready')

      Push::Daemon::Feeder.start(foreground)
    end

    protected

    def self.rescale_poolsize(size)
      # 1 feeder + providers
      size = 1 + size

      h = ActiveRecord::Base.connection_config
      h[:pool] = size
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
      puts "\nShutting down..."
      Push::Daemon::Feeder.stop
      Push::Daemon.delivery_handler_pool.drain if Push::Daemon.delivery_handler_pool

      self.providers.each do |provider|
        provider.stop
      end

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
      if !configuration[:pid_file].blank?
        begin
          File.open(configuration[:pid_file], 'w') do |f|
            f.puts $$
          end
        rescue SystemCallError => e
          logger.error("Failed to write PID to '#{configuration[:pid_file]}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = configuration[:pid_file]
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end
  end
end