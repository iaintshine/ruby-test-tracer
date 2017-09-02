module Wrapping
  class Span < OpenTracing::Span
    extend Forwardable

    def_delegators :@wrapped, :operation_name=, :set_tag, :set_baggage_item, :get_baggage_item, :log, :finish

    attr_reader :wrapped

    def initialize(span)
      @wrapped = span
    end

    def context
      Wrapping::SpanContext.new(@wrapped.context)
    end
  end
end
