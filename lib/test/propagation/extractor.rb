module Test
  module Propagation
    module Extractor
      # Extract a SpanContext from the given carrier.
      #
      # @param carrier [Carrier] A carrier object
      # @return [SpanContext, nil] the extracted SpanContext or nil if none could be found
      def extract(carrier)
      end
    end
  end
end
