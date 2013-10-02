module Push
  module Daemon
    extend self

    def start
      setup_signal_hooks
      daemonize unless Push.config.foreground
      write_pid_file

      App.load
      App.start
      Feedback.load
      Feedback.start
      DatabaseReconnectable.rescale_poolsize('Daemon', App.database_connections + Feedback.database_connections)

      Push.logger.info('[Daemon] Ready')
      Feeder.start
      shutdown
    end

    def shutdown
      if Push.config.single_run
        while ((test = Push::Message.ready_for_delivery.count) != 0)
          Push.logger.info "[Daemon] #{test} remaining"
          sleep 1
        end
      end
      App.stop
      Feedback.stop
      delete_pid_file
    end

    protected

    def setup_signal_hooks
      @shutting_down = false

      ['SIGINT', 'SIGTERM'].each do |signal|
        Signal.trap(signal) do
          handle_shutdown_signal
        end
      end
    end

    def handle_shutdown_signal
      exit 1 if @shutting_down
      @shutting_down = true
      Push.logger.info "[Daemon] Shutting down..."
      Feeder.stop unless Push.config.single_run
    end

    def daemonize
      Process.daemon
      reconnect_database
    end

    def write_pid_file
      if !Push.config.pid_file.blank?
        begin
          File.open(Push.config.pid_file, 'w') do |f|
            f.puts $$
          end
        rescue SystemCallError => e
          Push.logger.error("Failed to write PID to '#{Push.config.pid_file}': #{e.inspect}")
        end
      end
    end

    def delete_pid_file
      pid_file = Push.config.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end
  end
end