[![Build Status](https://travis-ci.org/iaintshine/ruby-test-tracer.svg?branch=master)](https://travis-ci.org/iaintshine/ruby-test-tracer)
# Test::Tracer

Fully OpenTracing compatible in-memory Tracer implementation which records all the spans, and includes methods which you might find helpful during testing. The tracer is fully agnostic to any testing framework.

The framework came to alive, because I had a constant need of some kind of "recording" tracer that I could use during tests of new instrumentation libraries for OpenTracing like rails-tracer, tracing-logger etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'test-tracer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install test-tracer

## Test::Tracer

In addition to OT compatible methods `Test::Tracer` provides the following methods:

1. `spans` returns all spans, including those in progress.
2. `finished_spans` returns only finished spans.

The tracer plays nicely with other wrapping tracers until your wrapped span, and span context implements `wrapped`
method. The method must return the wrapped item. You can customize the behaviour by implementing `Test::Wrapped::Extractor` and setting `wrapped_span_extractor` and/or `wrapped_span_context_extractor`.

### Usage

```ruby
require "test-tracer"

describe "Test::Tracer examples" do
  let(:tracer) { Test::Tracer.new }

  context "when we expect no traces" do
    it "does not have any traces started" do
      expect(tracer.spans).to be_empty
    end

    it "does not have any traces recorded" do
      expect(tracer.finished_spans).to be_empty
    end
  end

  context "when we expect traces to be present" do
    it "does have some traces started" do
      expect(tracer.spans).not_to be_empty
    end

    it "does have some traces recorded" do
      expect(tracer.finished_spans).not_to be_empty
    end
  end

  context "when we expect exactly N traces" do
    it "has N traces started" do
      expect(tracer.spans.size).to eq(N)
    end

    it "has N traces recorded" do
      expect(tracer.finished_spans.size).to eq(N)
    end
  end
end
```

## Test::Span

In addition to OT compatible methods `Test::Span` provides the following methods:

1. `tracer` returns the tracer the span was created by.
1. `in_progress?`, `started?`, `finished?` informs whether the span is in progress, or it's finished.
2. `start_time` returns when the span was started.
2. `end_time` returns when the span was finished, or nil if still in progress.
2. `tags` returns the span's tags.
2. `logs` returns the span's logs, an array of `Test::Span::LogEntry`s.

The modification operations e.g. `operation_name=`, `set_tag`, `set_baggage_item` on a span are not allowed after it's finished. It throws `Test::Span::SpanAlreadyFinished` exception. The same with `finish`. The span can be finished only once.

### Usage

```ruby
require "test-tracer"

describe "Test::Span examples" do
  let(:tracer) { Test::Tracer.new }

  context "when a new span was started" do
    let(:span) { tracer.start_span("operation name", tags: {'component' => 'ActiveRecord'}) }

    it "is in progress" do
      expect(span.in_progress?).to eq(true) 
    end

    it "does have the proper name" do
      expect(span.operation_name).to eq("operation name")
    end

    it "does include standard OT tags" do
      expect(span.tags).to include('component' => 'ActiveRecord')
    end

    it "does not have any log entries" do
      expect(span.logs).to be_empty
    end
  end

  context "when an event was logged" do
    let(:span) do 
      current_span = tracer.start_span("operation name")
      current_span.log(event: "exceptional message", severity: Logger::ERROR, pid: $1)
      current_span
    end

    it "does have some log entries recorded" do
      expect(span.logs).not_to be_empty
    end

    it "includes all the event attributes" do
      log = span.logs.first
      expect(log.event).to eq("exceptional message")
      expect(log.fields).to include(severity: Logger::ERROR)
    end
  end

  context "when a span was finished" do
    let(:span) { tracer.start_span("operation name").finish }

    it "is not in progress" do
      expect(span.in_progress?).to eq(false)
    end

    it "can't be finished twice" do
      expect { span.finish }.to raise_error(Test::Span::SpanAlreadyFinished)
    end
  end
end
```

## Test::SpanContext

Context propagation is fully implemented by the tracer, and is inspired by [Jaeger](http://jaeger.readthedocs.io/en/latest/) and [TraceContext](https://github.com/TraceContext/tracecontext-spec/pull/1/files). In addition to OT compatible methods `Test::SpanContext` provides the following methods:

1. `trace_id` returns the ID of the whole trace forest.
1. `span_id` returns the ID of the current span.
2. `parent_span_id` returns the ID of the parent span.


### Usage

```ruby
require "test-tracer"

describe "Test::SpanContext examples" do
  let(:tracer) { Test::Tracer.new }

  context "when a new span was started as child of root" do
    let(:root_context) { tracer.start_span("root span").context } 
    let(:child_context) { tracer.start_span("child span", child_of: root_context).context }

    it "all have the same trace_id" do
      expect(child_context.trace_id).to eq(root_context.trace_id)
    end

    it "propagates parent child relationship" do
      expect(child_context.parent_span_id).to eq(root_context.span_id)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iaintshine/ruby-test-tracer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

