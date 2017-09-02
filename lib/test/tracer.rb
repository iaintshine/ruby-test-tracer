require 'opentracing'

require_relative 'type_check'
require 'test/id_provider'
require 'test/span_context'
require 'test/span'
require 'test/propagation'
require 'test/wrapped'

module Test
  class Tracer < OpenTracing::Tracer
    include TypeCheck

    attr_reader :spans, :finished_spans
    attr_reader :injectors, :extractors

    attr_accessor :wrapped_span_extractor
    attr_accessor :wrapped_span_context_extractor

    attr_accessor :logger


    def initialize(logger: nil)
      @logger = logger

      @spans = []
      @finished_spans = []

      @injectors = {}
      @extractors = {}

      register_codec(OpenTracing::FORMAT_TEXT_MAP, Propagation::TextMapCodec.new)
      register_codec(OpenTracing::FORMAT_RACK, Propagation::RackCodec.new)

      default_extractor = Wrapped::DefaultExtractor.new
      @wrapped_span_extractor = default_extractor
      @wrapped_span_context_extractor = default_extractor
    end

    def register_injector(format, injector)
      NotNull! format
      Argument! injector.respond_to?(:inject), "Injector must respond to 'inject' method"

      @injectors[format] = injector
      self
    end

    def register_extractor(format, extractor)
      NotNull! format
      Argument! extractor.respond_to?(:extract), "Extractor must respond to 'extract' method"

      @extractors[format] = extractor
      self
    end

    def register_codec(format, codec)
      register_injector(format, codec)
      register_extractor(format, codec)
      self
    end

    # OT complaiant
    def start_span(operation_name, child_of: nil, references: nil, start_time: Time.now, tags: nil)
      child_of = extract_span(child_of) || extract_span_context(child_of)

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

    # OT complaiant
    def inject(span_context, format, carrier)
      NotNull! format
      span_context = extract_span_context(span_context)

      return unless carrier

      injector = @injectors[format]
      if injector
        injector.inject(span_context, carrier)
      else
        log(Logger::WARN, "No injector found for '#{format}' format")
      end
    end

    # OT complaiant
    def extract(format, carrier)
      NotNull! format
      NotNull! carrier

      extractor = @extractors[format]
      if extractor
        extractor.extract(carrier)
      else
        log(Logger::WARN, "No extractor found for '#{format}' format")
        nil
      end
    end

    def clear
      @spans.clear
      @finished_spans.clear
      self
    end

  private
    def log(severity, message)
      logger.log(severity, message) if logger
    end

    def extract_span(span)
      if Type?(span, ::Test::Span, NilClass)
        span
      else
        wrapped_span_extractor.extract(span) if wrapped_span_extractor
      end
    end

    def extract_span_context(span_context)
      if Type?(span_context, ::Test::SpanContext, NilClass)
        span_context
      else
        wrapped_span_context_extractor.extract(span_context) if wrapped_span_context_extractor
      end
    end
  end
end
