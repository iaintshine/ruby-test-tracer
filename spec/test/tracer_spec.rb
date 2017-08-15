require "spec_helper"

RSpec.describe Test::Tracer do
  describe "initial state" do
    it "has no open spans" do
      expect(Test::Tracer.new.spans).to be_empty
    end

    it "has no finished spans" do
      expect(Test::Tracer.new.finished_spans).to be_empty
    end
  end

  describe :start_span do
    let(:tracer) { Test::Tracer.new }

    it "returns instance of Span" do
      expect(tracer.start_span("test")).to be_instance_of(Test::Span)
    end

    describe "operation_name propagation" do
      it "sets operation_name on newly created span" do
        expect(tracer.start_span("test").operation_name).to eq("test")
      end
    end

    describe "tags propagation" do
      it "sets tags on newly created span" do
        tags = { 'span.kind' => 'client' }
        expect(tracer.start_span("test", tags: tags).tags).to eq(tags)
      end
    end

    describe "start_time propagation" do
      it "sets start_time on newly created span" do
        time = Time.now - 60
        expect(tracer.start_span("test", start_time: time).start_time).to eq(time)
      end
    end

    describe "context propagation" do
      it "creates new root context when no parent context passed" do
        expect(tracer.start_span("root").context.parent_span_id).to eq(nil)
      end

      it "propagates parent context when parent span passed" do
        root_span = tracer.start_span("root")
        child_span = tracer.start_span("child", child_of: root_span)

        expect(child_span.context.trace_id).to eq(root_span.context.trace_id)
        expect(child_span.context.parent_span_id).to eq(root_span.context.span_id)
      end

      it "propagates parent context when parent span context passed" do
        root_span_context = tracer.start_span("root").context
        child_span = tracer.start_span("child", child_of: root_span_context)

        expect(child_span.context.trace_id).to eq(root_span_context.trace_id)
        expect(child_span.context.parent_span_id).to eq(root_span_context.span_id)
      end
    end

    describe :spans do
      it "adds newely started span to spans collection" do
        span = tracer.start_span("span")

        expect(tracer.spans.size).to eq(1)
        expect(tracer.spans.first).to eq(span)
      end
    end

    describe :finished_spans do
      it "doesn't add newely started span to finished_spans collection" do
        tracer.start_span("span")

        expect(tracer.finished_spans).to be_empty
      end

      context "on span finish" do
        it "adds finished span to finished_spans collection" do
          span = tracer.start_span("span").finish

          expect(tracer.finished_spans.size).to eq(1)
          expect(tracer.finished_spans.first).to eq(span)
        end
      end
    end
  end

  describe :inject do
    let(:tracer) { Test::Tracer.new }
    let(:span) { tracer.start_span("root") }

    context "text map format" do
      it "propagates context" do
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(carrier["trace_id"]).to eq(span.context.trace_id)
        expect(carrier["span_id"]).to eq(span.context.span_id)
        expect(carrier["parent_span_id"]).to eq(span.context.parent_span_id)
      end
    end

    context "rack format" do
      it "propagates context" do
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_RACK, carrier)

        expect(carrier["X-Trace-Id"]).to eq(span.context.trace_id)
        expect(carrier["X-Span-Id"]).to eq(span.context.span_id)
        expect(carrier["X-Parent-Span-Id"]).to eq(span.context.parent_span_id)
      end
    end
  end

  describe :extract do
    let(:tracer) { Test::Tracer.new }
    let(:span) { tracer.start_span("root") }

    context "text map format" do
      it "extracts context" do
        carrier = {
          'trace_id' => span.context.trace_id,
          'span_id' => span.context.span_id,
          'parent_span_id' => span.context.parent_span_id
        }
        span_context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)

        expect(span_context).to be_instance_of(::Test::SpanContext)
        expect(span_context.trace_id).to eq(span.context.trace_id)
        expect(span_context.span_id).to eq(span.context.span_id)
        expect(span_context.parent_span_id).to eq(span.context.parent_span_id)
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
          'HTTP_X_TRACE_ID' => span.context.trace_id,
          'HTTP_X_SPAN_ID' => span.context.span_id,
          'HTTP_X_PARENT_SPAN_ID' => span.context.parent_span_id
        }
        span_context = tracer.extract(OpenTracing::FORMAT_RACK, carrier)

        expect(span_context).to be_instance_of(::Test::SpanContext)
        expect(span_context.trace_id).to eq(span.context.trace_id)
        expect(span_context.span_id).to eq(span.context.span_id)
        expect(span_context.parent_span_id).to eq(span.context.parent_span_id)
      end

      it "returns nil if headers not present" do
        carrier = {}
        span_context = tracer.extract(OpenTracing::FORMAT_RACK, carrier)

        expect(span_context).to eq(nil)
      end
    end
  end

  describe :clear do
    let(:tracer) do
      t = Test::Tracer.new
      t.start_span("span_1")
      t.start_span("span_2").finish
      t
    end

    it "clears open spans" do
      expect(tracer.clear.spans).to be_empty
    end

    it "clears finished spans" do
      expect(tracer.clear.finished_spans).to be_empty
    end
  end
end
