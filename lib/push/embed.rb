require 'push-core'
require 'push/daemon'

module Push
  class Embed

    def self.single_run(options = {})
      start_process(true, options)
    end

    def self.continuous(options = {})
      start_process(false, options)
    end

    def self.start_process(single_run, options)
      config = Push::Daemon::ConfigurationEmpty.new
      options.each { |k, v| config.send("#{k}=", v) }
      config.single_run = single_run
      config.foreground = true
      Push.config.update(config)
      Push::Daemon.start
    end

    def self.shutdown
      Push::Daemon::Feeder.stop
      Push::Daemon.shutdown
    end
  end
end