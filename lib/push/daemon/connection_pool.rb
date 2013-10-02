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

      def checkout(notification, name)
        notification_type = notification.use_connection
        if @connections.has_key?(notification_type.to_s)
          @connections[notification_type.to_s].pop
        else
          raise Push::DeliveryError.new(0, notification.id, "Unknown app: #{notification_type.to_s}", name, true)
        end
      end

      def size
        @connections.values.collect{|x| x.length }.inject(:+)
      end
    end
  end
end