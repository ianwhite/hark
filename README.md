# `heed` (and `hark`)

[![Gem Version](https://badge.fury.io/rb/heed.png)](https://rubygems.org/gems/heed)
[![Build Status](https://travis-ci.org/ianwhite/heed.png)](https://travis-ci.org/ianwhite/heed)
[![Dependency Status](https://gemnasium.com/ianwhite/heed.png)](https://gemnasium.com/ianwhite/heed)
[![Code Climate](https://codeclimate.com/github/ianwhite/heed.png)](https://codeclimate.com/github/ianwhite/heed)
[![Coverage Status](https://coveralls.io/repos/ianwhite/heed/badge.png)](https://coveralls.io/r/ianwhite/heed)

Create and use ad-hoc listeners with hark and heed.

## Installation

Add this line to your application's Gemfile:

    gem 'heed'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install heed

## What & Why?

**heed** enables you to use 'listener' objects very easily.  It's for programming in the *hexagonal* or *tell, don't ask* style.
The consumers of heed listeners don't know anything about heed.  Because heed makes it easy to create ad-hoc object, it's easy to get
started with a tell-dont-ask style, in rails controllers for example.  For more detail see the 'Rationale' section.

## Usage

### `hark`: create a listener

To create a listener object use `hark`.

You can pass a symbol and block

    hark :created do |user|
      redirect_to(user, notice: "You have signed up!")
    end

The following methods are more suitable for a listener with multiple messages.

A hash with callables as values

    hark(
      created: ->(user) { redirect_to(user, notice: "You have signed up!") },
      invalid: ->(user) { @user = user; render "new" }
    )

    # assuming some methods for rendering and redirecting exist on the controller
    hark(created: method(:redirect_to_user), invalid: method(:render_new))

Or, a 'respond_to' style block

    hark do |on|
      on.created {|user| redirect_to(user, notice: "You have signed up!") }
      on.invalid {|user| @user = user; render "new" }
    end

### Strict & lax listeners

By default, heed listeners are 'strict', they will only respond to the methods defined on them.

You create a 'lax' listener, responding to any message, by sending the `lax` message.

    listener = hark(:foo) { "Foo" }

    listener.bar
    # => NoMethodError: undefined method `bar' for #<Heed::StrictListener:0x007fc91a03e568>

    listener = listener.lax
    listener.bar
    # => []

To make a strict listener send the `strict` message.

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

Turn any object into a listener, adding new methods as we go

    hark UserLogger.new do |on|
      on.created {|user| Emailer.send_welcome_email(user) }
    end

Now, when listener is sent #created, all create handlers are called.

### `heed` call a message with an ad-hoc listener

Because of the precedence of the block operator, constructing ad-hoc listeners requires
you to insert some parens, which might be seen as unsightly, e.g:

    seller.request_valuation(item, (hark do |on|
      on.valuation_requested {|valuation| redirect_to valuation}
      on.invalid_item {|item| redirect_to item, error: "Item not evaluable" }
    end))

You may use #heed to create an ad-hoc listener using a passed block as follows

    heed seller, :request_valuation, item do |on|
      on.valuation_requested {|valuation| redirect_to valuation}
      on.invalid_item {|item| redirect_to item, error: "Item not evaluable" }
    end

If you want to combine listeners with an ad-hoc block, you may pass a 0-arity block that is
yielded as the listener.  This means you can use the block to wire up listeners, adding
extra ones that have the caller's binding (useful in controllers for example)

    heed seller, :request_valuation, item do
      hark valuation_notifier do |on|
        on.valuation_requested {|valuation| redirect_to valuation}
        on.invalid_item {|item| redirect_to item, error: "Item not evaluable" }
      end
    end

### Return value

Using the return value of a listener is not encouraged.  Heed is designed for a *tell, don't ask*
style of coding.  That said the return value of a heed listener is an array of its handlers return values.

    a = hark(:foo) { 'a' }
    b = Object.new.tap {|o| o.singleton_class.send(:define_method, :foo) { 'b' } }
    c = hark(foo: -> { 'c' }, bar: -> { 'c bar' })

    a.foo           # => ["a"]
    hark(a,b).foo   # => ["a", "b"]
    hark(a,b,c).foo # => ["a", "b", "c"]

### Immutable

Heed listeners are immutable and `#lax`, `#strict`, and `#heed` all return new listeners.

## Rationale

When programming in the 'tell-dont-ask' or 'hexagonal' style, program flow is managed by passing listener, or
response, objects to service objects, which call back depending on what happened.  This allows logic that is concerned with the caller's domain to remain isolated from the service object.

The idea behind **heed** is that there should be little ceremony involved in the listener/response mechanics, and
that simple listeners can easily be refactored into objects in their own right, without changing the protocols between
the calling and servcie objects.

To that end, service objects should not know anything other than the listener/response protocol, and shouldn't have to 'publish' their
results beyond a simple method call.

As a simple example, a user creation service object defines a response protocol as follows:

* created_user(user) _the user was succesfully created_
* invalid_user(user) _the user couldn't be created because it was invalid_

The UserCreator object's main method will have some code as follows:

    if # some logic that means the user params were valid and we could persist the user
      response.created_user(user)
    else
      response.invalid_user(user)
    end

Let's say a controller is calling this, and you are using heed.  In the beginning you would do something like this:

    def create
      heed user_creator, :create_user, user_params do |on|
        on.created_user {|user| redirect_to user, notice: "Welome!" }
        on.invalid_user {|user| @user = user; render "new" }
      end
    end

This keeps the controller's handling of the user creation nicely separate from the saving of the user creator.

Then, a requirement comes in to log the creation of users.  The first attempt might be this:

    def create
      heed user_creator, :create_user, user_params do |on|
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
      heed user_creator, :create_user, user_params do
        hark ui_response, UserEmailer.new, ux_team_response
      end
    end

    # UserEmailer responds to #created_user(user)

    def ui_response
      hark do |on|
        on.created_user {|user| redirect_to user, notice: "Welome!" }
        on.invalid_user {|user| @user = user; render "new" }
      end
    end

    def ux_team_response
      hark(:invalid_user) {|user| logger.info("User invalid: #{user}") }
    end

If some of the response code gets hairy, we can easily swap out heed ad-hoc objects for 'proper' ones.
For example, the UI response might get a bit hairy, and so we make a new object.

    def create
      heed user_creator, :create_user, user_params do
        hark UiResponse.new(self), UserEmailer.new, ux_team_response
      end
    end

    class UiResponse < SimpleDelegator
      def created_user user
        if request.format.json?
          # ...
        else
          # ...
        end
      end

      def invalid_user user
        # ...
      end
    end

Note that throughout this process we didn't have to modify the UserCreator code, even when we transitioned
to/from heed/hark for different repsonses/styles.

### Testing your listeners

Don't pay any attention to heed when you're testing, heed is just a utility to create listeners, and so what
you should be testing is the protocol.

For example the service object tests will test functionality that pertains to the actual creation of the user,
and will test that the correct message is sent to the response in those circumstances.  Whereas the controller tests
will mock out the service object, and test what happens when the service object sends the messages to the response as
dictated by the protocol.

    describe UserCreator do
      let(:service) { described_class.new }

      describe "#call params, response" do
        subject { service.call params, response }

        let(:response) { double }

        context "when the user succesfully saves"
          let(:params) { {name: "created user", # and other successful user params }

          it "sends #created_user to the response with the created user" do
            response.should_receive(:created_user) do |user|
              user.name.should == "created user"
            end
            subject
          end
        end

        context "when the user succesfully saves"
          let(:params) { {name: "invalid user", # and invalid user params }

          it "sends #invalid_user to the response with the created user" do
            response.should_receive(:invalid_user) do |user|
              # test that the object passed is the invalid user
            end
            subject
          end
        end
      end
    end

    describe NewUserController do
      before { controller.stub(user_creator: user_creator) } # or some other sensible way of injecting a fake user_creator

      let(:user_creator) { double "User creator" }
      let(:user) { double "A user" }

      context "when the user_creator is succesful" do
        before do
          user_creator.stub :call do |params, response|
            response.created_user(user)
          end
        end

        it "should redirect to the user"

        it "should email the user"

        it "should log the creation of the user"
      end

      context "when the user_creator says the params are invalid" do
        before do
          user_creator.stub :call do |params, response|
            response.invalid_user(user)
          end
        end

        it "should render new with the user"

        it "should log something for the UX team"
      end
    end

    Note that in the above tests, there is *no mention of hark or heed*.  This ensures a smooth transition to 'full blown'
    response objects should the need occur.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
