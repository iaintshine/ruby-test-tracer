require "spec_helper"

RSpec.describe Test::SpanContext do
  describe :attributes do
    let(:trace_id) { Test::IdProvider.generate }
    let(:span_id) { Test::IdProvider.generate }
    let(:parent_span_id) { Test::IdProvider.generate }
    let(:baggage) { {authenticated_user_id: 1} }
    let(:span_context) do
      Test::SpanContext.new(trace_id: trace_id,
                            span_id: span_id,
                            parent_span_id: parent_span_id,
                            baggage: baggage)
    end

    it "returns proper value for trace_id" do
      expect(span_context.trace_id).to eq(trace_id)
    end

    it "returns proper value for span_id" do
      expect(span_context.span_id).to eq(span_id)
    end

    it "returns proper value for parent_span_id" do
      expect(span_context.parent_span_id).to eq(parent_span_id)
    end

    it "returns proper value for baggage" do
      expect(span_context.baggage).to eq(baggage)
    end
  end

  describe :root do
    it "creates new trace_id" do
      expect(Test::SpanContext.root.trace_id).not_to be_empty
    end

    it "creates new span_id" do
      expect(Test::SpanContext.root.span_id).not_to be_empty
    end

    it "returns nil for parent_span_id" do
      expect(Test::SpanContext.root.parent_span_id).to eq(nil)
    end

    it "returns an empty hash for baggage" do
      expect(Test::SpanContext.root.baggage).to be_instance_of(Hash)
      expect(Test::SpanContext.root.baggage).to be_empty
    end
  end

  describe :child_of do
    let(:parent_context) do
      Test::SpanContext.new(trace_id: Test::IdProvider.generate,
                            span_id: Test::IdProvider.generate,
                            baggage: { authenticated_user_id: 1 })
    end

    it "copies trace_id from parent_context" do
      expect(Test::SpanContext.child_of(parent_context).trace_id).to eq(parent_context.trace_id)
    end

    it "creates new span_id" do
      span_id = Test::SpanContext.child_of(parent_context).span_id
      expect(span_id).not_to be_empty
      expect(span_id).not_to eq(parent_context.span_id)
      expect(span_id).not_to eq(parent_context.parent_span_id)
    end

    it "copies parent_context span_id as parent_span_id" do
      expect(Test::SpanContext.child_of(parent_context).parent_span_id).to eq(parent_context.span_id)
    end

    it "copies baggage from parent_context" do
      expect(Test::SpanContext.child_of(parent_context).baggage).to eq(parent_context.baggage)
    end
  end

  describe "equality operator" do
    it "returns true for same instances" do
      context1 = Test::SpanContext.root

      expect(context1).to eq(context1)
    end

    it "returns true for objects with the same state" do
      context1 = Test::SpanContext.root
      context2 = context1.dup

      expect(context1).to eq(context2)
    end

    it "returns false for objects with differnet state" do
      context1 = Test::SpanContext.root
      context2 = Test::SpanContext.root

      expect(context1).not_to eq(context2)
    end
  end
end
