require "bundler/setup"
require "test-tracer"
require "support/wrapping_tracer"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def build_span_context(opts = {})
    Test::SpanContext.new({
      trace_id: Test::IdProvider.generate,
      span_id: Test::IdProvider.generate
    }.merge(opts))
  end

  def build_span(tracer, opts = {})
    span_context = opts.delete(:span_context) || build_span_context
    operation_name = opts.delete(:operation_name) || 'operation-name'

    Test::Span.new(tracer: tracer, context: span_context, operation_name: operation_name, **opts)
  end
end
