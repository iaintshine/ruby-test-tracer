module Test
  module Propagation
    class RackCodec
      module Headers
        TRACE_ID = "X-Trace-Id".freeze
        SPAN_ID = "X-Span-Id".freeze
        PARENT_SPAN_ID = "X-Parent-Span-Id".freeze

        module Rack
          TRACE_ID = "HTTP_X_TRACE_ID".freeze
          SPAN_ID = "HTTP_X_SPAN_ID".freeze
          PARENT_SPAN_ID = "HTTP_X_PARENT_SPAN_ID".freeze
        end
      end

      def inject(span_context, carrier)
        carrier[Headers::TRACE_ID] = span_context.trace_id
        carrier[Headers::SPAN_ID] = span_context.span_id
        carrier[Headers::PARENT_SPAN_ID] = span_context.parent_span_id
      end

      def extract(carrier)
        trace_id = carrier[Headers::Rack::TRACE_ID]
        span_id = carrier[Headers::Rack::SPAN_ID]
        parent_span_id = carrier[Headers::Rack::PARENT_SPAN_ID]

        if trace_id && span_id
          SpanContext.new(trace_id: trace_id,
                          span_id: span_id,
                          parent_span_id: parent_span_id)
        end
      end
    end
  end
end
