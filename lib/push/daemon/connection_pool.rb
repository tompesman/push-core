module Push
  module Daemon
    class ConnectionPool
      def initialize()
        @connections = Hash.new
      end

      def populate(provider)
        @connections[provider.connectiontype.to_s] = Queue.new
        provider.pushconnections.times do |i|
          c = provider.connectiontype.new(provider, i+1)
          c.connect
          checkin(c)
        end
      end

      def checkin(connection)
        @connections[connection.class.to_s].push(connection)
      end

      def checkout(notification_type)
        @connections[notification_type.to_s].pop
      end

      def size
        @connections.values.collect{|x| x.length }.inject(:+)
      end
    end
  end
end