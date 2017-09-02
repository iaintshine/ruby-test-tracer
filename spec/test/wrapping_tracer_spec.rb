require "spec_helper"

RSpec.describe "Test::Tracer with Wrapping::Tracer" do
  describe :start_span do
    let(:test_tracer) { Test::Tracer.new }
    let(:tracer) { Wrapping::Tracer.new(test_tracer) }

    describe :spans do
      it "adds newely started span to spans collection" do
        tracer.start_span("span")

        expect(test_tracer.spans.size).to eq(1)
      end
    end

    describe :finished_spans do
      it "doesn't add newely started span to finished_spans collection" do
        tracer.start_span("span")

        expect(test_tracer.finished_spans).to be_empty
      end

      context "on span finish" do
        it "adds finished span to finished_spans collection" do
          tracer.start_span("span").finish

          expect(test_tracer.finished_spans.size).to eq(1)
        end
      end
    end

    describe "context propagation" do
      it "creates new root context when no parent context passed" do
        span = tracer.start_span("root")
        expect(span.wrapped.context.parent_span_id).to eq(nil)
      end

      it "propagates parent context when parent span passed" do
        root_span = tracer.start_span("root")
        child_span = tracer.start_span("child", child_of: root_span)

        expect(child_span.wrapped.context.trace_id).to eq(root_span.wrapped.context.trace_id)
        expect(child_span.wrapped.context.parent_span_id).to eq(root_span.wrapped.context.span_id)
      end

      it "propagates parent context when parent span context passed" do
        root_span_context = tracer.start_span("root").context
        child_span = tracer.start_span("child", child_of: root_span_context)

        expect(child_span.wrapped.context.trace_id).to eq(root_span_context.wrapped.trace_id)
        expect(child_span.wrapped.context.parent_span_id).to eq(root_span_context.wrapped.span_id)
      end
    end
  end

  describe :inject do
    let(:test_tracer) { Test::Tracer.new }
    let(:tracer) { Wrapping::Tracer.new(test_tracer) }
    let(:span) { tracer.start_span("root") }

    context "nil carrier" do
      it "doesn't throw any exceptions" do
        carrier = nil
        expect { tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier) }.not_to raise_error
      end
    end

    context "text map format" do
      it "propagates context" do
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(carrier["trace_id"]).to eq(span.wrapped.context.trace_id)
        expect(carrier["span_id"]).to eq(span.wrapped.context.span_id)
        expect(carrier["parent_span_id"]).to eq(span.wrapped.context.parent_span_id)
      end
    end

    context "rack format" do
      it "propagates context" do
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_RACK, carrier)

        expect(carrier["X-Trace-Id"]).to eq(span.wrapped.context.trace_id)
        expect(carrier["X-Span-Id"]).to eq(span.wrapped.context.span_id)
        expect(carrier["X-Parent-Span-Id"]).to eq(span.wrapped.context.parent_span_id)
      end
    end
  end

  describe :extract do
    let(:test_tracer) { Test::Tracer.new }
    let(:tracer) { Wrapping::Tracer.new(test_tracer) }
    let(:span) { tracer.start_span("root") }

    context "text map format" do
      it "extracts context" do
        carrier = {
          'trace_id' => span.wrapped.context.trace_id,
          'span_id' => span.wrapped.context.span_id,
          'parent_span_id' => span.wrapped.context.parent_span_id
        }
        span_context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(span_context.wrapped.trace_id).to eq(span.wrapped.context.trace_id)
        expect(span_context.wrapped.span_id).to eq(span.wrapped.context.span_id)
        expect(span_context.wrapped.parent_span_id).to eq(span.wrapped.context.parent_span_id)
      end

      it "returns nil if attributes not present" do
        carrier = {}
        span_context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(span_context).to eq(nil)
      end
    end

    context "rack format" do
      it "extracts context" do
        carrier = {
          'HTTP_X_TRACE_ID' => span.wrapped.context.trace_id,
          'HTTP_X_SPAN_ID' => span.wrapped.context.span_id,
          'HTTP_X_PARENT_SPAN_ID' => span.wrapped.context.parent_span_id
        }
        span_context = tracer.extract(OpenTracing::FORMAT_RACK, carrier)

        expect(span_context.wrapped.trace_id).to eq(span.wrapped.context.trace_id)
        expect(span_context.wrapped.span_id).to eq(span.wrapped.context.span_id)
        expect(span_context.wrapped.parent_span_id).to eq(span.wrapped.context.parent_span_id)
      end

      it "returns nil if headers not present" do
        carrier = {}
        span_context = tracer.extract(OpenTracing::FORMAT_RACK, carrier)

        expect(span_context).to eq(nil)
      end
    end
  end
end
