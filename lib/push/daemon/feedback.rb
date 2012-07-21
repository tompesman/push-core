module Push
  module Daemon
    module Feedback
      class << self
        attr_accessor :queue, :handler, :feeder
      end

      def self.load(config)
        return if config.feedback_poll == 0
        self.queue = DeliveryQueue.new
        self.handler = Feedback::FeedbackHandler.new(Rails.root + config.feedback_processor)
        self.feeder = Feedback::FeedbackFeeder.new(config.feedback_poll)
      end

      def self.start
        return if self.handler.nil? or self.feeder.nil?
        self.handler.start
        self.feeder.start
        @started = true
      end

      def self.stop
        return unless @started
        self.feeder.stop
        self.handler.stop
      end

      def self.database_connections
        @started ? 2 : 0
      end
    end
  end
end