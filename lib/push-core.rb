require 'push/railtie' if defined?(Rails)

require 'push/daemon/configuration'
require 'push/daemon/logger'

require 'push/daemon/interruptible_sleep'
require 'push/daemon/delivery_error'
require 'push/daemon/disconnection_error'
require 'push/daemon/connection_pool'
require 'push/daemon/database_reconnectable'
require 'push/daemon/delivery_handler'
require 'push/daemon/feedback'
require 'push/daemon/feedback/feedback_feeder'
require 'push/daemon/feedback/feedback_handler'
require 'push/daemon/feeder'
require 'push/daemon/app'

module Push
  def self.config
    @config ||= Push::Daemon::Configuration.new
  end

  def self.configure
    yield config if block_given?
  end

  def self.logger
    @logger ||= Push::Daemon::Logger.new(foreground: config.foreground, error_notification: config.error_notification)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
