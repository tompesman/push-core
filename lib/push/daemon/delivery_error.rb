module Push
  class DeliveryError < StandardError
    attr_reader :code, :description, :notify

    def initialize(code, message_id, description, source, notify = true)
      @code = code
      @message_id = message_id
      @description = description
      @source = source
      @notify = notify
    end

    def message
      "Unable to deliver message #{@message_id}, received #{@source} error #{@code} (#{@description})"
    end
  end
end