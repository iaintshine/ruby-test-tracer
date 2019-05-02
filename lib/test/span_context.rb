module Test
  class SpanContext < OpenTracing::SpanContext
    class << self
      def root
        new(trace_id: IdProvider.generate,
            span_id: IdProvider.generate)
      end

      def child_of(parent_context)
        new(trace_id: parent_context.trace_id,
            span_id: IdProvider.generate,
            parent_span_id: parent_context.span_id,
            baggage: parent_context.baggage)
      end
    end

    include TypeCheck

    attr_reader :trace_id, :span_id, :parent_span_id

    def initialize(trace_id:, span_id:, parent_span_id: nil, baggage: {})
      Type! trace_id, String
      Type! span_id, String
      Type! parent_span_id, String, NilClass
      Type! baggage, Hash

      super(baggage: baggage)

      @trace_id = trace_id
      @span_id = span_id
      @parent_span_id = parent_span_id
      @baggage = baggage
    end

    def set_baggage_item(key, value)
      @baggage[key.to_s] = value.to_s
    end

    def get_baggage_item(key)
      @baggage[key.to_s]
    end

    def to_s
      "SpanContext(trace_id=#{trace_id}, span_id=#{span_id}, parent_span_id=#{parent_span_id}, baggage=#{baggage})"
    end

    def ==(rhs)
      self.class == rhs.class &&
        trace_id == rhs.trace_id &&
        span_id == rhs.span_id &&
        parent_span_id == rhs.parent_span_id &&
        baggage == rhs.baggage
    end
  end
end
