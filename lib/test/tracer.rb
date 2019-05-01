require 'opentracing'

require 'test/type_check'
require 'test/id_provider'
require 'test/span_context'
require 'test/scope_manager'
require 'test/scope'
require 'test/span'
require 'test/propagation'
require 'test/wrapped'

module Test
  class Tracer < OpenTracing::Tracer
    include TypeCheck

    attr_reader :spans, :finished_spans
    attr_reader :scope_manager
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
      @scope_manager = ScopeManager.new
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

    # OT compliant
    def start_active_span(operation_name,
                          child_of: nil,
                          references: nil,
                          start_time: Time.now,
                          tags: {},
                          ignore_active_scope: false,
                          finish_on_close: true,
                          **)
      span = start_span(
        operation_name,
        child_of: child_of,
        references: references,
        start_time: start_time,
        tags: tags,
        ignore_active_scope: ignore_active_scope
      )
      scope = @scope_manager.activate(span, finish_on_close: finish_on_close)

      if block_given?
        begin
          yield scope
        ensure
          scope.close
        end
      else
        scope
      end
    end

    # OT compliant
    def start_span(operation_name,
                   child_of: nil,
                   references: nil,
                   start_time: Time.now,
                   tags: nil,
                   ignore_active_scope: false,
                   **)

      new_context = prepare_span_context(
        child_of: child_of,
        references: references,
        ignore_active_scope: ignore_active_scope
      )

      new_span = Span.new(tracer: self,
                          operation_name: operation_name,
                          context: new_context,
                          start_time: start_time,
                          references: references,
                          tags: tags)
      @spans << new_span
      if block_given?
        begin
          yield(new_span)
        ensure
          new_span.finish
        end
      else
        new_span
      end
    end

    # OT compliant
    # active_span method it is implemented in OpenTracing tracer
    # def active_span
    #   scope = scope_manager.active
    #   scope.span if scope
    # end

    # OT compliant
    def inject(span_context, format, carrier)
      NotNull! format
      span_context = extract_wrapped_span_context(span_context)

      return unless carrier

      injector = @injectors[format]
      if injector
        injector.inject(span_context, carrier)
      else
        log(Logger::WARN, "No injector found for '#{format}' format")
      end
    end

    # OT compliant
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

    def prepare_span_context(child_of:, references:, ignore_active_scope:)
      context =
        context_from_child_of(child_of) ||
        context_from_references(references) ||
        context_from_active_scope(ignore_active_scope)

      context = extract_wrapped_span_context(context)
      if context
        ::Test::SpanContext.child_of(context)
      else
        ::Test::SpanContext.root
      end
    end

    def context_from_child_of(child_of)
      return nil unless child_of
      child_of.respond_to?(:context) ? child_of.context : child_of
    end

    def context_from_references(references)
      return nil if !references || references.none?

      # Prefer CHILD_OF reference if present
      ref = references.detect do |reference|
        reference.type == OpenTracing::Reference::CHILD_OF
      end
      (ref || references[0]).context
    end

    def log(severity, message)
      logger.log(severity, message) if logger
    end

    def context_from_active_scope(ignore_active_scope)
      return if ignore_active_scope

      active_scope = @scope_manager.active
      active_scope.span.context if active_scope
    end

    def extract_wrapped_span_context(span_context)
      if Type?(span_context, ::Test::SpanContext, NilClass)
        span_context
      else
        wrapped_span_context_extractor.extract(span_context) if wrapped_span_context_extractor
      end
    end
  end
end
