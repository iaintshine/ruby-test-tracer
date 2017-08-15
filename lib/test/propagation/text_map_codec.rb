module Test
  module Propagation
    class TextMapCodec
      TRACE_ID = "trace_id".freeze
      SPAN_ID = "span_id".freeze
      PARENT_SPAN_ID = "parent_span_id".freeze

      def inject(span_context, carrier)
        carrier[TRACE_ID] = span_context.trace_id
        carrier[SPAN_ID] = span_context.span_id
        carrier[PARENT_SPAN_ID] = span_context.parent_span_id
      end

      def extract(carrier)
        trace_id = carrier[TRACE_ID]
        span_id = carrier[SPAN_ID]
        parent_span_id = carrier[PARENT_SPAN_ID]

        if trace_id && span_id
          SpanContext.new(trace_id: trace_id,
                          span_id: span_id,
                          parent_span_id: parent_span_id)
        end
      end
    end
  end
end
