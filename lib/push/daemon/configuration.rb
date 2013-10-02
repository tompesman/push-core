module Push
  module Daemon
    CONFIG_ATTRS = [:foreground, :pid_file, :push_poll, :error_notification,
                    :feedback_poll, :feedback_processor, :single_run]

    class ConfigurationEmpty < Struct.new(*CONFIG_ATTRS)
    end

    class Configuration < Struct.new(*CONFIG_ATTRS)

      def initialize
        super
        set_defaults
      end

      def update(other)
        CONFIG_ATTRS.each do |attr|
          other_value = other.send(attr)
          send("#{attr}=", other_value) unless other_value.nil?
        end
      end

      def pid_file=(path)
        if path && !Pathname.new(path).absolute?
          super(File.join(Rails.root, path))
        else
          super
        end
      end

      def feedback_processor=(path)
        if path && !Pathname.new(path).absolute?
          super(File.join(Rails.root, path))
        else
          super
        end
      end

      def set_defaults
        self.foreground = false
        self.pid_file = nil
        self.push_poll = 2
        self.error_notification = false
        self.feedback_poll = 60
        self.feedback_processor = 'lib/push/feedback_processor'
        self.single_run = false
      end
    end
  end
end
