module Push
  class DeliveryError < StandardError
    attr_reader :code, :description

    def initialize(code, message_id, description, source)
      @code = code
      @message_id = message_id
      @description = description
      @source = source
    end

    def message
      "Unable to deliver message #{@message_id}, received #{@source} error #{@code} (#{@description})"
    end
  end
end