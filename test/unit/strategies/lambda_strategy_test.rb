require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::LambdaStrategy do
  subject do
    Flipflop::Strategies::LambdaStrategy.new.freeze
  end

  describe "with defaults" do
    it "should have default name" do
      assert_equal "lambda", subject.name
    end

    it "should not have default description" do
      assert_equal "Resolves feature settings with custom code.",
        subject.description
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end
  end

  describe "with lambda" do
    attr_accessor :features

    before do
      self.features = {}
    end

    subject do
      features = self.features
      Flipflop::Strategies::LambdaStrategy.new(lambda: ->(feature) { features[feature] }).freeze
    end

    describe "with enabled feature" do
      before do
        features[:one] = true
      end

      it "should have feature enabled" do
        assert_equal true, subject.enabled?(:one)
      end
    end

    describe "with disabled feature" do
      before do
        features[:two] = false
      end

      it "should not have feature enabled" do
        assert_equal false, subject.enabled?(:two)
      end
    end

    describe "with unknown feature" do
      it "should not know feature" do
        assert_nil subject.enabled?(:three)
      end
    end
  end

  describe "with request lambda" do
    subject do
      Flipflop::Strategies::LambdaStrategy.new(lambda: ->(feature) {
        request.params[feature]
      }).freeze
    end

    before do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = create_request
    end

    after do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
    end

    describe "with enabled feature" do
      before do
        subject.send(:request).params[:one] = true
      end

      it "should have feature enabled" do
        assert_equal true, subject.enabled?(:one)
      end
    end
  end

  describe "with non conforming parameters" do
    subject do
      Flipflop::Strategies::LambdaStrategy.new(lambda: ->() { }).freeze
    end

    it "should raise error" do
      assert_raises Flipflop::StrategyError do
        subject
      end
    end

    it "should raise with message" do
      message = nil
      begin
        subject
      rescue => err
        message = err.message
      end
      assert_equal "Strategy 'lambda' has lambda with arity 0, expected 1 or -1.", message
    end
  end

  describe "with non conforming return value" do
    subject do
      Flipflop::Strategies::LambdaStrategy.new(lambda: ->(feature) {
        return feature
      }).freeze
    end

    it "should raise error" do
      assert_raises Flipflop::StrategyError do
        subject.enabled?(:one)
      end
    end

    it "should raise with message" do
      message = nil
      begin
        subject.enabled?(:one)
      rescue => err
        message = err.message
      end
      assert_equal "Strategy 'lambda' returned invalid result :one for feature 'one'.", message
    end
  end
end
