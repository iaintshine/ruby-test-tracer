module Test
  module Wrapped
    class DefaultExtractor
      def extract(wrapper)
        wrapper.wrapped if wrapper.respond_to?(:wrapped)
      end
    end
  end
end
