# Hark

Create an ad-hoc listener object with hark.

The idea behind hark is that the objects that receive listeners shouldn't need to perform any ceremony on
them, just treat them as objects that respond to messages.  It's up to the caller to provide these lsitener objects,
and to decide how they behave (re: lax), perhaps smushing together listeners (re: add).  If required, these ad-hoc
listeners can easily be refactored into classes in their own right, as the recievers don't need to know anything about
hark.

  listener = hark success: ->{ "succeeded" }, failure: ->{ "failed" }
  listener.success # => ["succeeded"]
  listener.failure # => ["failed"]
  listener.unknown # raises NoMethodError

Listeners return an array of return values, but using return values is discouraged (tell don't ask)

To create a listener that silently swallows unknown messages, send it the #lax method

  listener = hark(success: ->{ "succeeded" }).lax
  listener.success # => ["succeeded"]
  listener.unknown # => []

To make a lax listener strict again, send it the #strict method

  listener = listener.strict

To smush together listeners, use #hark

  listener = listener.hark other_listener
  listener = listener.hark emailer, logger
  listener = hark(emailer, logger, twitter_notifier)

To add new messages to a listener, use #hark

  listener = listener.hark(:success) { "extra success" }
  listener.success # => ["success", "extra success"]

To decorate an object (of any sort) so that it becomes a hark listener (and therefore can be smushed etc)

  listener = object.to_hark

The listener is immutable, #strict, #lax, and #hark all return new listeners

## Installation

Add this line to your application's Gemfile:

    gem 'hark'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hark

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
