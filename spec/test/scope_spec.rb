# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Test::Scope do
  let(:operation_name) { 'span_name' }
  let(:tracer) { Test::Tracer.new }
  let(:scope_stack) { Test::ScopeManager::ScopeStack.new }
  let(:span) { build_span(tracer) }

  describe :attributes do
    let(:scope) { Test::Scope.new(span, scope_stack, finish_on_close: true) }

    it 'returns proper value for closed' do
      expect(scope.closed?).to be_falsey
    end

    it 'returns proper value for span' do
      expect(scope.span).to eq(span)
    end
  end

  describe :close do
    let(:scope) { Test::Scope.new(span, scope_stack, finish_on_close: finish_on_close) }
    let(:finish_on_close) { true }

    before(:each) do
      scope_stack.push(scope)
    end

    it 'throws error if some other scope is currently active' do
      another_span = build_span(tracer)
      another_scope = Test::Scope.new(another_span, scope_stack, finish_on_close: true)
      scope_stack.push(another_scope)

      expect { scope.close }.to raise_error(RuntimeError, /non-active/)
    end

    it 'removes self from scope stack' do
      expect(scope.scope_stack.stack).to eq([scope])
      scope.close
      expect(scope.scope_stack.stack).to eq([])
    end

    context 'finished on close is true' do
      let(:finish_on_close) { true }
      it 'closes the scope with span' do
        scope.close
        expect(scope.closed?).to be_truthy
        expect(scope.span.finished?).to be_truthy
      end
    end

    context 'finished on close is false' do
      let(:finish_on_close) { false }

      it 'closes the scope and keeps the span opened' do
        scope.close
        expect(scope.closed?).to be_truthy
        expect(scope.span.in_progress?).to be_truthy
      end
    end
  end
end
