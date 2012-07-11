module Push
  module Daemon
    module Feedback
      class FeedbackFeeder
        include ::Push::Daemon::DatabaseReconnectable
        include ::Push::Daemon::InterruptibleSleep

        def initialize(poll)
          @poll = poll
        end

        def name
          "FeedbackFeeder"
        end

        def start
          Thread.new do
            loop do
              break if @stop
              enqueue_feedback
              interruptible_sleep @poll
            end
          end
        end

        def stop
          @stop = true
          interrupt_sleep
        end

        protected

        def enqueue_feedback
          begin
            with_database_reconnect_and_retry(name) do
              if Push::Daemon.feedback_queue.notifications_processed?
                Push::Feedback.ready_for_followup.find_each do |feedback|
                  Push::Daemon.feedback_queue.push(feedback)
                end
              end
            end
          rescue StandardError => e
            Push::Daemon.logger.error(e)
          end
        end
      end
    end
  end
end
