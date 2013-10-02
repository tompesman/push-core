module Push
  module Daemon
    module Feedback
      class << self
        attr_accessor :queue, :handler, :feeder
      end

      def self.name
        "Feedback"
      end

      def self.load
        return if Push.config.feedback_poll == 0
        self.queue = Queue.new
        self.handler = Feedback::FeedbackHandler.new(Rails.root + Push.config.feedback_processor)
        self.feeder = Feedback::FeedbackFeeder.new(Push.config.feedback_poll)
      end

      def self.start
        return if self.handler.nil? or self.feeder.nil?
        self.handler.start
        self.feeder.start
        @started = true
      end

      def self.stop
        return unless @started
        Push.logger.info "[#{name}] stopping"
        self.feeder.stop
        self.handler.stop
        Push.logger.info "[#{name}] stopped"
      end

      def self.database_connections
        @started ? 2 : 0
      end
    end
  end
end