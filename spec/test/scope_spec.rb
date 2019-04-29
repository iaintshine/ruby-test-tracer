require "spec_helper"

RSpec.describe Test::Scope do
  describe :attributes do
    let(:span_context) { Test::SpanContext.root }
    let(:operation_name) { "span_name" }
    let(:tracer) { Test::Tracer.new }
    let(:span) { Test::Span.new(tracer: tracer, context: span_context, operation_name: operation_name) }
    let(:scope) do
      Test::Scope.new(span, span_context, finish_on_close: true)
    end

    it "returns proper for closed" do
      expect(scope).to be
    end
  end

  describe :root do
  end
end
