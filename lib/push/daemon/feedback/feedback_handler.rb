module Push
  module Daemon
    module Feedback
      class FeedbackHandler
        attr_reader :name

        def initialize(processor)
          @name = "FeedbackHandler"
          @queue = Push::Daemon::Feedback.queue
          require processor
        end

        def start
          @thread = Thread.new do
            loop do
              break if @stop
              handle_next_feedback
            end
          end
        end

        def stop
          @stop = true
          @queue.wakeup(@thread)
        end

        protected

        def handle_next_feedback
          begin
            feedback = @queue.pop
          rescue DeliveryQueue::WakeupError
            return
          end

          begin
            Push::FeedbackProcessor.process(feedback)
          rescue StandardError => e
            Push::Daemon.logger.error(e)
          ensure
            feedback.is_processed(@name)
            @queue.notification_processed
          end
        end
      end
    end
  end
end