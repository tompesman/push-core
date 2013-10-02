module Push
  module Daemon
    module Feedback
      class FeedbackHandler
        EXIT = :exit

        def initialize(processor)
          @queue = Push::Daemon::Feedback.queue
          require processor
        end

        def name
          "FeedbackHandler"
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
          @queue.push(EXIT) if @thread
          @thread.join if @thread
        end

        protected

        def handle_next_feedback
          feedback = @queue.pop
          return if feedback == EXIT

          begin
            Push::FeedbackProcessor.process(feedback)
          rescue StandardError => e
            Push.logger.error(e)
          ensure
            feedback.is_processed(name)
          end
        end
      end
    end
  end
end