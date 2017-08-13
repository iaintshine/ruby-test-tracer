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

## Test::Span

In addition to OT compatible methods `Test::Span` provides the following methods:

1. `tracer` returns the tracer the span was created by.
1. `in_progress?` informs whether the span is in progress, or it's finished.
2. `start_time` returns when the span was started.
2. `end_time` returns when the span was finished, or nil if still in progress.
2. `tags` returns the span's tags.
2. `logs` returns the span's logs, an array of `Test::Span::LogEntry`s.

The modification operations e.g. `operation_name=`, `set_tag`, `set_baggage_item` on a span are not allowed after it's finished. It throws `Test::Span::SpanAlreadyFinished` exception. The same with `finish`. The span can be finished only once.

## Test::SpanContext

Context propagation is fully implemented by the tracer, and is inspired by [Jaeger](http://jaeger.readthedocs.io/en/latest/) and [TraceContext](https://github.com/TraceContext/tracecontext-spec/pull/1/files). In addition to OT compatible methods `Test::SpanContext` provides the following methods:

1. `trace_id` returns the ID of the whole trace forest.
1. `span_id` returns the ID of the current span.
2. `parent_span_id` returns the ID of the parent span.

## Usage

```ruby
gem 'test-tracer'

tracer = Test::Tracer.new

root_span = tracer.start_span("root")
tracer.spans # => will include root_span
child_span = tracer.start_span("child", child_of: root_span)
tracer.spans # => will include both root_span, child_span 

child_span.finish
tracer.finished_spans # => will include child_span
root_span.finish
tracer.finished_spans # => will include child_span, root_span
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iaintshine/ruby-test-tracer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

