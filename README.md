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

**hark** enables you to create a 'listener' object very easily.  It's for programming in the *hexagonal* or *tell, don't ask* style.
The consumers of hark listeners don't know anything about hark.  Because hark makes it easy to create ad-hoc object, it's easy to get
started with a tell-dont-ask style, in rails controllers for example.  For more detail see the 'Rationale' section.

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
    b = Object.new.tap {|o| o.singleton_class.send(:define_method, :foo) { 'b' } }
    c = hark(foo: -> { 'c' }, bar: -> { 'c bar' })

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

    if # some logic that means the user params were valid and we could persist the user
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
      response = hark(ui_response, UserEmailer.new, ux_team_response)
      user_creator.call user_params, response
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

If some of the response code gets hairy, we can easily swap out hark ad-hoc objects for 'proper' ones.
For example, the UI response might get a bit hairy, and so we make a new object.

    def create
      response = hark(UiResponse.new(self), UserEmailer.new, ux_team_response)
      user_creator.call user_params, response
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
to/from hark for different repsonses/styles.

### Testing your listeners

Don't pay any attention to hark when you're testing, hark is just a utility to create listeners, and so what
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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
