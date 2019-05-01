# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Test::ScopeManager do
  let(:scope_manager) { Test::ScopeManager.new }
  let(:tracer) { Test::Tracer.new }
  let(:span) { build_span(tracer) }

  describe :activate do
    it 'returns scope' do
      scope = scope_manager.activate(span)
      expect(scope).to be_instance_of(Test::Scope)
    end

    it 'propagates finish_on_close to scope' do
      scope = scope_manager.activate(span, finish_on_close: false).close
      expect(scope.closed?).to be_truthy
      expect(scope.span.finished?).to be_falsey
    end

    it 'returns the same scope if it is active one' do
      scope = scope_manager.activate(span)
      the_same_scope = scope_manager.activate(span)
      expect(scope_manager.scope_stack.stack.size).to eq(1)
      expect(scope).to eq(the_same_scope)
    end
  end

  describe :active do
    let(:last_span) { build_span(tracer) }

    it 'returns last activated element' do
      scope_manager.activate(span)
      last_scope = scope_manager.activate(last_span)
      expect(scope_manager.active).to eq(last_scope)
      expect(scope_manager.active.span).to eq(last_span)
    end

    it 'doesn\'t remove active scope' do
      last_scope = scope_manager.activate(span)
      expect(scope_manager.active).to eq(last_scope)
      expect(scope_manager.active).to eq(last_scope)
    end
  end

  describe :stack do
    it 'allows to inspect whole scope stack' do
      spans = Array.new(5) { |i| build_span(tracer, operation_name: "test_span_#{i}" )}
      spans.each do |span|
        scope_manager.activate(span)
      end
      expect(scope_manager.scope_stack.stack.first.span.operation_name).to eq(spans.first.operation_name)
      expect(scope_manager.scope_stack.stack.map { |scope| scope.span.operation_name }).to eq(spans.map(&:operation_name))
    end
  end
end
