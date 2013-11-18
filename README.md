# Hark

[![Gem Version](https://badge.fury.io/rb/ianwhite-hark.png)](https://rubygems.org/gems/ianwhite-hark)
[![Build Status](https://travis-ci.org/ianwhite/hark.png)](https://travis-ci.org/ianwhite/hark)
[![Dependency Status](https://gemnasium.com/ianwhite/hark.png)](https://gemnasium.com/ianwhite/hark)
[![Code Climate](https://codeclimate.com/github/ianwhite/hark.png)](https://codeclimate.com/github/ianwhite/hark)
[![Coverage Status](https://coveralls.io/repos/ianwhite/hark/badge.png)](https://coveralls.io/r/ianwhite/hark)

Create a ad-hoc listeners with hark.

## Installation

Add this line to your application's Gemfile:

    gem 'ianwhite-hark', :require => 'hark'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ianwhite-hark

## What & Why?

**hark** enables you to create a 'listener' object very easily.  It's for programming in the 'hexagonal' or 'tell, do not ask' style.
The consumers of hark listeners don't know anything about hark.  This makes refactoring easier.  For more detail see the 'Rationale' section.

## Usage

### Create a listener

To create a listener object use `hark`.

You can pass a symbol and block

    hark :created do |user|
      redirect_to(user, notice: "You have signed up!")
    end

The following methods are more suitable for a listener with multiple messages.

A hash with callables as keys

    hark(
      created: ->(user) { redirect_to(user, notice: "You have signed up!") },
      invalid: ->(user) { @user = user; render "new" }
    )

    # assuming some methods for rendering and redirecting exist on the controller
    hash created: method(:redirect_to_user), invalid: method(:render_new)

Or, a 'respond_to' style block

    hark do |on|
      on.created {|user| redirect_to(user, notice: "You have signed up!") }
      on.invalid {|user| @user = user; render "new" }
    end

### Strict & lax listeners

By default, hark listeners are 'strict', they will only respond to the methods defined on them.

You create a 'lax' listener, responding to any message, by sending the `lax` message.

    listener = hark(:foo) { "Foo" }

    listener.bar
    # => NoMethodError: undefined method `bar' for #<Hark::StrictListener:0x007fc91a03e568>

    listener = listener.lax
    listener.bar
    # => []

### Combining listeners

Here are some ways of combining listeners.

    # redirect listener
    listener = hark(created: method(:redirect_to_user))

Add a message

    listener = listener.hark :created do |user|
      WelomeMailer.send_email(user)
    end

Combine with another listener

    logger = listener.hark(created: ->(u) { logger.info "User #{u} created" } )
    listener = listener.hark(logger)

Combine with any object that support the same protocol

    logger = UserLogger.new # responds to :created
    listener = listener.hark(logger)

Now, when listener is sent #created, all create handlers are called.

### Return value

Using the return value of a listener is not encouraged.  Hark is designed for a *tell, don't ask*
style of coding.  That said the return value of a hark listener is an array of its handlers return values.

    a = hark(:foo) { 'a' }
    b = hark(:foo) { 'b' }
    c = hark(:foo) { 'c' }

    a.foo           # => ["a"]
    hark(a,b).foo   # => ["a", "b"]
    hark(a,b,c).foo # => ["a", "b", "c"]

## Rationale

When programming in the 'tell-dont-ask' or 'hexagonal' style, program flow is managed by passing listener, or
response, objects to service objects, which call back depending on what happened.  This allows logic that is concerned with the caller's domain to remain isolated from the service object.

The idea behind **hark** is that there should be little ceremony involved in the listener/response mechanics, and
that simple listeners can easily be refactored into objects in their own right, without changing the protocols between
the calling and servcie objects.

To that end, service objects should not know anything other than the listener/response protocol, and shouldn't have to 'publish' their
results beyond a simple method call.

As a simple example, a user creation service object defines a response protocol as follows:

* created_user(user) _the user was succesfully created_
* invalid_user(user) _the user couldn't be created because it was invalid_

The UserCreator object's main method will have some code as follows:

    if user.save
      response.created_user(user)
    else
      response.invalid_user(user)
    end

Let's say a controller is calling this, and you are using hark.  In the beginning you would do something like this:

    def create
      user_creator.call(user_params, hark do |on|
        on.created_user {|user| redirect_to user, notice: "Welome!" }
        on.invalid_user {|user| @user = user; render "new" }
      end)
    end

This keeps the controller's handling of the user creation nicely separate from the saving of the user creator.

Then, a requirement comes in to log the creation of users.  The first attempt might be this:

    def create
      user_creator.call(user_params, hark do |on|
        on.created_user do |user|
          redirect_to user, notice: "Welome!"
          logger.info "User #{user} created"
        end
        on.invalid_user {|user| @user = user; render "new" }
      end
    end

Then a requirement comes in to email users on succesful creation, there's an UserEmailer that responds
to the same protocol.  Also, the UX team want to log invalid users.

There's quite a lot going on now, we can tie it up as follows:

    def create
      listener = hark(UserEmailer.new, crud_response, ux_team_response)
      user_creator.call user_params, listener
    end

    # UserEmailer responds to #created_user(user)

    def crud_response
      hark do |on|
        on.created {|user| redirect_to user, notice: "Welome!" }
        on.invalid {|user| @user = user; render "new" }
      end
    end

    def ux_team_response
      hark(:invalid) {|user| logger.info("User invalid: #{user}") }
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
