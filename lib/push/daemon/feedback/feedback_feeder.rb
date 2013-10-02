module Push
  module Daemon
    module Feedback
      class FeedbackFeeder
        include ::Push::Daemon::DatabaseReconnectable

        def initialize(poll)
          @interruptible_sleeper = InterruptibleSleep.new(poll)
        end

        def name
          "FeedbackFeeder"
        end

        def start
          @thread = Thread.new do
            loop do
              @interruptible_sleeper.sleep
              break if @stop
              enqueue_feedback
            end
          end
        end

        def stop
          @stop = true
          @interruptible_sleeper.interrupt_sleep
          @thread.join if @thread
        end

        protected

        def enqueue_feedback
          begin
            with_database_reconnect_and_retry(name) do
              if Push::Daemon::Feedback.queue.empty?
                Push::Feedback.ready_for_followup.find_each do |feedback|
                  Push::Daemon::Feedback.queue.push(feedback)
                end
              end
            end
          rescue StandardError => e
            Push.logger.error(e)
          end
        end
      end
    end
  end
end
