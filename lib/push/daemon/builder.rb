module Push
  module Daemon
    class Builder
      def initialize(&block)
        instance_eval(&block) if block_given?
      end

      def daemon(options)
        Push::Daemon.configuration = options
      end

      def feedback(options)
        Push::Daemon.feedback_configuration = options
      end

      def provider(klass, options)
        begin
          middleware = Push::Daemon.const_get("#{klass}".camelize)
        rescue NameError
          raise LoadError, "Could not find matching push provider for #{klass.inspect}. You may need to install an additional gem (such as push-#{klass})."
        end

        Push::Daemon.providers << middleware.new(options)
      end
    end
  end
end