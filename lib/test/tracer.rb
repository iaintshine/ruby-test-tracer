require 'opentracing'

require_relative 'type_check'
require_relative 'id_provider'
require_relative 'span_context'
require_relative  'span'

module Test
  class Tracer < OpenTracing::Tracer
    include TypeCheck

    attr_reader :spans, :finished_spans

    def initialize
      @spans = []
      @finished_spans = []
    end

    def start_span(operation_name, child_of: nil, references: nil, start_time: Time.now, tags: nil)
      Type! child_of, ::Test::Span, ::Test::SpanContext, NilClass

      parent_context = child_of && child_of.respond_to?(:context) ? child_of.context : child_of
      new_context = parent_context ? ::Test::SpanContext.child_of(parent_context) : ::Test::SpanContext.root

      new_span = Span.new(tracer: self,
                          operation_name: operation_name,
                          context: new_context,
                          start_time: start_time,
                          tags: tags)
      @spans << new_span
      new_span
    end

    def clear
      @spans.clear
      @finished_spans.clear
      self
    end
  end
end
