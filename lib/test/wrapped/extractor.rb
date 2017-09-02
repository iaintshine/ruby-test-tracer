module Test
  module Wrapped
    module Extractor
      # Extract a wrapped span or span context.
      #
      # @param wrapper
      # @return [Span, SpanContext, nil] the extracted Span, SpanContext or nil if none could be found
      def extract(wrapper)
      end
    end
  end
end
