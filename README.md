# Hark [![Code Climate](https://codeclimate.com/github/ianwhite/hark.png)](https://codeclimate.com/github/ianwhite/hark) [![Build Status](https://travis-ci.org/ianwhite/hark.png)](https://travis-ci.org/ianwhite/hark)

Create an ad-hoc listener object with hark.

## Installation

Add this line to your application's Gemfile:

    gem 'ianwhite-hark', :require => 'hark'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ianwhite-hark

## Usage

The idea behind hark is that the objects that receive listeners shouldn't need to perform any ceremony on
them, just treat them as objects that respond to messages.  It's up to the caller to provide these lsitener objects,
and to decide how they behave, perhaps combining together listeners (in an subscriber fashion).  If required, these ad-hoc
listeners can easily be refactored into classes in their own right, as the recievers don't need to know anything about
hark.

Tell don't ask style is encouraged with hark.  That said, the return value for a message sent to a hark listener is an array of all of the return values.

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

    listener = hark(object)

The listener is immutable, #strict, #lax, and #hark all return new listeners

Here's an example from a rails controller

    def create
      SignupNewUser.new params, hark(create_response, SignupEmailer.new)
    end

    # response block style
    def create_response
      hark do |on|
        on.signed_up {|user| redirect_to user, notice: "Signed up!" }
        on.invalid {|user| render "new", user: user }
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
