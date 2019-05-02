require "spec_helper"

RSpec.describe Test::Tracer do
  describe "initial state" do
    it "has no open spans" do
      expect(Test::Tracer.new.spans).to be_empty
    end

    it "has no finished spans" do
      expect(Test::Tracer.new.finished_spans).to be_empty
    end

    it 'has ready scope manager with empty scope stack' do
      tracer = Test::Tracer.new
      expect(tracer.scope_manager).to be_instance_of(Test::ScopeManager)
      expect(tracer.scope_manager.active).to be_nil
    end
  end

  describe 'active_span' do
    it 'returns correct scope' do
      tracer = Test::Tracer.new
      span = tracer.start_span("span")
      tracer.scope_manager.activate(span)
      expect(tracer.active_span).to eq(span)
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

    it 'works corretly with passed in block' do
      return_value = 'expected_value'
      block_value = tracer.start_span("test") do |span|
        expect(span).to be_instance_of(Test::Span)
        return_value
      end
      expect(block_value).to eq(return_value)
    end

    describe "references propagation" do
      it "sets references on newly created span" do
        parent_context = build_span_context
        reference = OpenTracing::Reference.child_of(parent_context)
        span = tracer.start_span("test_span", references: [reference])
        expect(span.references.size).to eq(1)
        expect(span.context.parent_span_id).to eq(parent_context.span_id)
        expect(span.references.first.context).to eq(parent_context)
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

      describe 'active scope propagation' do
        context 'no active span is present' do
          it "creates separate root parants if there is no parent and no active span" do
            root_span = tracer.start_span("root")
            another_root_span = tracer.start_span("another_root")

            expect(root_span.context.parent_span_id).to be_nil
            expect(another_root_span.context.parent_span_id).to be_nil
          end
        end

        context 'active span is present' do
          let(:root_span) { build_span(tracer, operation_name: "root") }

          before(:each) do
            tracer.scope_manager.activate(root_span)
          end

          it "creates span and sets its parent span to active span" do
            span = tracer.start_span("test_span")
            expect(span.context.parent_span_id).to eq(root_span.context.span_id)
          end

          it "ignore active span if specified by ignore_active_scope" do
            span = tracer.start_span("test_span", ignore_active_scope: true)
            expect(span.context.parent_span_id).to be_nil
          end
        end
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
        it 'automatically finish span if start_span received block' do
          returned_span = tracer.start_span("span") { |span| span }

          expect(tracer.finished_spans.size).to eq(1)
          expect(tracer.finished_spans.first).to eq(returned_span)
        end

        it "adds finished span to finished_spans collection" do
          span = tracer.start_span("span").finish

          expect(tracer.finished_spans.size).to eq(1)
          expect(tracer.finished_spans.first).to eq(span)
        end
      end
    end

    describe 'scope_manager scope stack' do
      it "start_span doesn't add to scope stack" do
        tracer.start_span("span")
        expect(tracer.scope_manager).to be_instance_of(Test::ScopeManager)
        expect(tracer.scope_manager.scope_stack.stack).to eq([])
        expect(tracer.scope_manager.active).to be_nil
      end
    end
  end

  describe :start_active_span do
    let(:tracer) { Test::Tracer.new }

    it "returns instance of Scope" do
      expect(tracer.start_active_span('root')).to be_instance_of(Test::Scope)
    end

    describe "operation_name propagation" do
      it "sets operation_name on newly created span" do
        expect(tracer.start_active_span("test").span.operation_name).to eq("test")
      end
    end

    describe "tags propagation" do
      it "sets tags on newly created span" do
        tags = { 'span.kind' => 'client' }
        expect(tracer.start_active_span("test", tags: tags).span.tags).to eq(tags)
      end
    end

    describe "start_time propagation" do
      it "sets start_time on newly created span" do
        time = Time.now - 60
        expect(tracer.start_active_span("test", start_time: time).span.start_time).to eq(time)
      end
    end

    it 'works corretly with passed in block' do
      return_value = 'expected_value'
      block_value = tracer.start_active_span("test") do |scope|
        expect(scope).to be_instance_of(Test::Scope)
        return_value
      end
      expect(block_value).to eq(return_value)
    end

    describe 'scope_manager scope stack' do
      it "adds to scope stack" do
        scope = tracer.start_active_span('test')
        expect(scope.closed?).to be_falsey
        expect(tracer.scope_manager.scope_stack.stack).to eq([scope])
        expect(tracer.active_span).to eq(scope.span)
      end

      it 'adds and removes active scope to scope stack for brief moment if start_active_span received block' do
        returned_scope = tracer.start_active_span('test') do |scope|
          expect(tracer.active_span).to eq(scope.span)
          expect(scope.closed?).to be_falsey
          scope
        end

        expect(returned_scope.closed?).to be_truthy
        expect(tracer.active_span).to be_nil
      end

      it 'nests correctly' do
        tracer.start_active_span('parent_span') do |parent_scope|
          expect(tracer.active_span).to eq(parent_scope.span)
          tracer.start_active_span('child_span') do |child_scope|
            expect(tracer.active_span).to eq(child_scope.span)
            expect(tracer.scope_manager.scope_stack.stack).to eq([parent_scope, child_scope])
            expect(child_scope.span.context.parent_span_id).to eq(parent_scope.span.context.span_id)
          end
        end
      end
    end

    describe "references propagation" do
      it "sets references on newly created span" do
        parent_context = build_span_context
        reference = OpenTracing::Reference.child_of(parent_context)
        scope = tracer.start_active_span("test_span", references: [reference])
        expect(scope.span.references.size).to eq(1)
        expect(scope.span.context.parent_span_id).to eq(parent_context.span_id)
        expect(scope.span.references.first.context).to eq(parent_context)
      end
    end

    describe 'finish_on_close propagation' do
      it 'sets finish_on_close in new scope' do
        expect(tracer.start_active_span("test_span", finish_on_close: false).finish_on_close).to be_falsey
      end
    end

    describe "context propagation" do
      it "creates new root context when no parent context passed" do
        expect(tracer.start_active_span("root").span.context.parent_span_id).to be_nil
      end

      it "propagates parent context when parent span passed" do
        root_scope = tracer.start_active_span("root")
        child_scope = tracer.start_active_span("child", child_of: root_scope.span)

        expect(child_scope.span.context.trace_id).to eq(root_scope.span.context.trace_id)
        expect(child_scope.span.context.parent_span_id).to eq(root_scope.span.context.span_id)
      end

      it "propagates parent context when parent span context passed" do
        root_scope = tracer.start_active_span("root")
        child_scope = tracer.start_active_span("child", child_of: root_scope.span.context)

        expect(child_scope.span.context.trace_id).to eq(root_scope.span.context.trace_id)
        expect(child_scope.span.context.parent_span_id).to eq(root_scope.span.context.span_id)
      end

      describe 'active scope propagation' do
        context 'no active span is present' do
          it "creates separete root parants if there is no parent and no active span" do
            scope = tracer.start_active_span("child")
            expect(scope.span.context.parent_span_id).to be_nil
            expect(tracer.active_span).to eq(scope.span)
          end
        end

        context 'active span is present' do
          it "creates span and sets its parent span to active span" do
            parent_scope = tracer.start_active_span('root')
            child_scope = tracer.start_active_span("child")
            expect(child_scope.span.context.parent_span_id).to eq(parent_scope.span.context.span_id)
          end

          it "ignore active span if specified by ignore_active_scope" do
            tracer.start_active_span('root')
            child_scope = tracer.start_active_span("child", ignore_active_scope: true)
            expect(child_scope.span.context.parent_span_id).to be_nil
          end
        end
      end
    end

    describe :spans do
      let(:scope_stack) { tracer.scope_manager.scope_stack }

      it "adds newely started span to spans collection" do
        span = tracer.start_active_span("test_span").span

        expect(tracer.spans.size).to eq(1)
        expect(tracer.spans.first).to eq(span)
        expect(scope_stack.stack.size).to eq(1)
        expect(scope_stack.stack.first.span).to eq(span)
      end
    end

    describe :finished_spans do
      let(:scope_stack) { tracer.scope_manager.scope_stack }

      it "doesn\'t add newely started active span to finished_spans collection" do
        span = tracer.start_active_span("span").span

        expect(scope_stack.stack.size).to eq(1)
        expect(scope_stack.stack.first.span).to eq(span)
        expect(tracer.finished_spans).to be_empty
      end

      context "on span finish" do
        it "automatically finish span if start_active_span received block" do
          span = tracer.start_active_span("span") do |scope|
            scope.span
          end

          expect(scope_stack.stack.size).to eq(0)
          expect(tracer.active_span).to be_nil
          expect(tracer.finished_spans.size).to eq(1)
          expect(tracer.finished_spans.first).to eq(span)
        end

        it "adds finished span to finished_spans collection" do
          scope = tracer.start_active_span("span").close

          expect(tracer.active_span).to be_nil
          expect(tracer.finished_spans.size).to eq(1)
          expect(tracer.finished_spans.first).to eq(scope.span)
        end
      end
    end
  end

  describe :inject do
    let(:tracer) { Test::Tracer.new }
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
