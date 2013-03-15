module Push
  module Daemon
    class App
      extend DatabaseReconnectable
      class << self
        attr_reader :apps
      end

      @apps = {}

      def self.load
        with_database_reconnect_and_retry('App.load') do
          configurations = Push::Configuration.enabled
          configurations.each do |config|
            if @apps[config.app] == nil
              @apps[config.app] = App.new(config.app)
            end
            @apps[config.app].configs << config
          end
        end
      end

      def self.ready
        ready = []
        @apps.each { |app, runner| ready << app if runner.ready? }
        ready
      end

      def self.deliver(notification)
        if app = @apps[notification.app]
          app.deliver(notification)
        else
          Rapns::Daemon.logger.error("No such app '#{notification.app}' for notification #{notification.id}.")
        end
      end

      def self.start
        @apps.values.map(&:start)
      end

      def self.stop
        @apps.values.map(&:stop)
      end

      def self.database_connections
        @apps.empty? ? 0 : @apps.values.collect{|x| x.database_connections }.inject(:+)
      end

      def initialize(name)
        @name = name
        @configs = []
        @handlers = []
        @providers = []
        @queue = DeliveryQueue.new
        @database_connections = 0
      end

      attr_accessor :configs
      attr_reader :database_connections

      def deliver(notification)
        @queue.push(notification)
      end

      def start
        @connection_pool = ConnectionPool.new
        @configs.each do |config|
          provider = load_provider(config.name, config.properties.merge({:connections => config.connections, :name => config.app}))
          @providers << provider
          @database_connections += provider.totalconnections
          @connection_pool.populate(provider)
        end
        @connection_pool.size.times do |i|
          @handlers << start_handler(i)
        end
      end

      def stop
        @handlers.map(&:stop)
        @providers.map(&:stop)
      end

      def ready?
        @queue.notifications_processed?
      end

      protected

      def start_handler(i)
        handler = DeliveryHandler.new(@queue, @connection_pool, "#{@name} #{i}")
        handler.start
        handler
      end

      def load_provider(klass, options)
        begin
          middleware = Push::Daemon.const_get("#{klass}".camelize)
        rescue NameError
          raise LoadError, "Could not find matching push provider for #{klass.inspect}. You may need to install an additional gem (such as push-#{klass})."
        end

        middleware.new(options)
      end
    end
  end
end