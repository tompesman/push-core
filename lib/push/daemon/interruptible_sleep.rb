module Push
  module Daemon
    class InterruptibleSleep
      def initialize(timeout)
        @timeout = timeout
        @sleep_reader, @wake_writer = IO.pipe
      end

      # wait for the given timeout in seconds, or data was written to the pipe
      # or the udp wakeup port if enabled.
      # @return [boolean] true if the sleep was interrupted, or false
      def sleep
        read_ports = [@sleep_reader]
        rs, = IO.select(read_ports, nil, nil, @timeout) rescue nil

        # consume all data on the readable io's so that our next call will wait for more data
        if rs && rs.include?(@sleep_reader)
          while true
            begin
              @sleep_reader.read_nonblock(1)
            rescue IO::WaitReadable
              break
            end
          end
        end
      end

      # writing to the pipe will wake the sleeping thread
      def interrupt_sleep
        @wake_writer.write('.')
      end

      # def close
      #   @sleep_reader.close rescue nil
      #   @wake_writer.close rescue nil
      # end
    end
  end
end