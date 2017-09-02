module Wrapping
  class Tracer < OpenTracing::Tracer
    extend Forwardable
    def_delegators :@wrapped, :inject

    attr_reader :wrapped

    def initialize(tracer)
      @wrapped = tracer
    end

    def start_span(operation_name, **args)
      span = @wrapped.start_span(operation_name, **args)
      Wrapping::Span.new(span)
    end

    def extract(format, carrier)
      span_context = @wrapped.extract(format, carrier)
      Wrapping::SpanContext.new(span_context) if span_context
    end
  end
end
