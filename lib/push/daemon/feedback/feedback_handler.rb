module Push
  module Daemon
    module Feedback
      class FeedbackHandler
        attr_reader :name
        STOP = 0x666

        def initialize(processor)
          @name = "FeedbackHandler"
          require processor
        end

        def start
          Thread.new do
            loop do
              break if @stop
              handle_next_feedback
            end
          end
        end

        def stop
          @stop = true
          Push::Daemon.feedback_queue.push(STOP)
        end

        protected

        def handle_next_feedback
          feedback = Push::Daemon.feedback_queue.pop

          if feedback == STOP
            return
          end

          begin
            Push::FeedbackProcessor.process(feedback)
            feedback.is_processed(@name)
          rescue StandardError => e
            Push::Daemon.logger.error(e)
          ensure
            Push::Daemon.feedback_queue.notification_processed
          end
        end
      end
    end
  end
end