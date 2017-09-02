module Wrapping
  class SpanContext < OpenTracing::SpanContext
    extend Forwardable

    def_delegators :@wrapped, :baggage

    attr_reader :wrapped

    def initialize(span_context)
      @wrapped = span_context
    end
  end
end
