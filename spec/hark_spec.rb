require 'spec_helper'
require 'hark'

describe Hark do
  let(:transcript) { [] }

  class PlainListener < Struct.new(:transcript)
    def success(value)
      transcript.push [:succeeded, value]
    end

    def failure(value)
      transcript.push [:failed, value]
    end
  end

  shared_examples_for "a success/failure listener" do
    describe "success" do
      before { listener.success(42) }
      it { transcript.should == [[:succeeded, 42]] }
    end

    describe "failure" do
      before { listener.failure(54) }
      it { transcript.should == [[:failed, 54]] }
    end
  end

  shared_examples_for "a strict listener" do
    it { strict_listener.should_not respond_to(:unknown) }
    it { expect{ strict_listener.unknown }.to raise_error(NoMethodError) }
  end

  shared_examples_for "a lax listener" do
    it { lax_listener.should respond_to(:unknown) }
    it { lax_listener.unknown.should == [] }
  end

  shared_examples_for "a success/failure hark listener" do
    it_should_behave_like "a success/failure listener"
    it_should_behave_like "a strict listener" do
      let(:strict_listener) { listener }
    end

    context "when made lax" do
      let(:lax_listener) { listener.lax }
      it_should_behave_like "a lax listener"

      context "and made strict again" do
        let(:strict_listener) { lax_listener.strict }
        it_should_behave_like "a strict listener"
      end
    end
  end

  describe "A plain (non hark) listener object" do
    let(:listener) { PlainListener.new(transcript) }

    it_should_behave_like "a success/failure listener"
    it_should_behave_like "a strict listener" do
      let(:strict_listener) { listener }
    end
  end

  describe "hark with respond_to style block" do
    let(:listener) do
      hark do |on|
        on.success {|v| transcript.push [:succeeded, v] }
        on.failure {|v| transcript.push [:failed, v] }
      end
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark with callables" do
    let(:listener) do
      hark :success => lambda{|v| transcript.push [:succeeded, v] }, :failure => lambda{|v| transcript.push [:failed, v] }
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark built up in steps" do
    let(:listener) do
      l = hark
      l = l.hark(:success) {|v| transcript.push [:succeeded, v] }
      l = l.hark(:failure) {|v| transcript.push [:failed, v] }
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark object" do
    let(:listener) { hark PlainListener.new(transcript) }

    it_should_behave_like "a success/failure hark listener"
  end

  describe "combine two listeners together" do
    let(:logger) { hark(:signup_user) {|user| transcript << "User #{user} signed up" } }
    let(:emailer) { hark(:signup_user) {|user| transcript << "Emailed #{user}" } }

    let(:listener) { logger.hark(emailer) }

    before { listener.signup_user("Fred") }

    it { transcript.should == ["User Fred signed up", "Emailed Fred"] }
  end

  describe "lax/strict is preserved on #hark" do
    it { hark.lax.hark.should be_a Hark::LaxListener }
    it { hark.strict.hark.should be_a Hark::StrictListener }
  end

  describe "when methods return falsy" do
    let(:listener) { hark(:foo) { false } }

    it { expect{ listener.foo }.to_not raise_error }
    it { listener.foo.should == [false] }
  end
end
