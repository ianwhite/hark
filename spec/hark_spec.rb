require 'spec_helper'
require 'hark'

describe Hark do
  Given(:transcript) { [] }

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
      When { listener.success(42) }
      Then { transcript == [[:succeeded, 42]] }
    end

    describe "failure" do
      When { listener.failure(54) }
      Then { transcript == [[:failed, 54]] }
    end
  end

  shared_examples_for "a strict listener" do
    Then { ! strict_listener.respond_to?(:unknown) }
    And  { (strict_listener.unknown rescue $!).is_a?(NoMethodError) }
  end

  shared_examples_for "a lax listener" do
    Then { lax_listener.respond_to?(:unknown) }
    And  { lax_listener.unknown == [] }
  end

  shared_examples_for "a success/failure hark listener" do
    it_should_behave_like "a success/failure listener"
    it_should_behave_like "a strict listener" do
      Given(:strict_listener) { listener }
    end

    context "when made lax" do
      Given(:lax_listener) { listener.lax }
      it_should_behave_like "a lax listener"

      context "and made strict again" do
        Given(:strict_listener) { lax_listener.strict }
        it_should_behave_like "a strict listener"
      end
    end
  end

  describe "A plain (non hark) listener object" do
    Given(:listener) { PlainListener.new(transcript) }

    it_should_behave_like "a success/failure listener"
    it_should_behave_like "a strict listener" do
      Given(:strict_listener) { listener }
    end
  end

  describe "hark with respond_to style block" do
    Given(:listener) do
      hark do |on|
        on.success {|v| transcript.push [:succeeded, v] }
        on.failure {|v| transcript.push [:failed, v] }
      end
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark with callables" do
    Given(:listener) do
      hark success: ->(v){ transcript.push [:succeeded, v] }, failure: ->(v){ transcript.push [:failed, v] }
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark built up in steps" do
    Given(:listener) do
      l = hark
      l = l.hark(:success) {|v| transcript.push [:succeeded, v] }
      l = l.hark(:failure) {|v| transcript.push [:failed, v] }
    end

    it_should_behave_like "a success/failure hark listener"
  end

  describe "hark object" do
    Given(:listener) { hark PlainListener.new(transcript) }

    it_should_behave_like "a success/failure hark listener"
  end

  describe "combine two listeners together" do
    Given(:logger) { hark(:signup_user) {|user| transcript << "User #{user} signed up" } }
    Given(:emailer) { hark(:signup_user) {|user| transcript << "Emailed #{user}" } }

    Given(:listener) { logger.hark(emailer) }

    When { listener.signup_user("Fred") }

    Then { transcript == ["User Fred signed up", "Emailed Fred"] }
  end

  describe "lax/strict is preserved on #hark" do
    Then { hark.lax.hark.is_a? Hark::LaxListener }
    Then { hark.strict.hark.is_a? Hark::StrictListener }
  end
end
