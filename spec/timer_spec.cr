require "./spec_helper"

describe Timer do
  it "works with Time::Span" do
    foo = nil

    timer = Timer.new(0.5.seconds) do
      foo = "bar"
    end

    sleep(0.6.seconds)

    foo.should eq "bar"
  end

  it "works with Time" do
    foo = nil

    timer = Timer.new(Time.utc + 0.5.seconds) do
      foo = "bar"
    end

    sleep(0.6.seconds)

    foo.should eq "bar"
  end

  it "works with select" do
    select
    when Timer.new(0.5.seconds)
      true.should be_true
    end
  end

  describe "#postpone" do
    it do
      foo = nil

      timer = Timer.new(0.5.seconds) do
        foo = "bar"
      end

      sleep(0.25.seconds)

      timer.postpone(0.5.seconds)

      sleep(0.35.seconds)
      foo.should be_nil # 0.6 seconds passed, it would already be fired if not postponed

      sleep(0.5.seconds)
      foo.should eq "bar"
    end
  end

  describe "#reschedule" do
    it do
      foo = nil

      timer = Timer.new(1.second) do
        foo = "bar"
      end

      sleep(0.1.seconds)

      timer.reschedule(Time.utc + 0.2.seconds)

      sleep(0.1.seconds)
      foo.should be_nil

      sleep(0.2.seconds)
      foo.should eq "bar"
    end

    context "when called multiple times" do
      foo = nil

      timer = Timer.new(1.second) do
        foo = "bar"
      end

      sleep(0.1.seconds)

      timer.reschedule(Time.utc + 0.2.seconds)

      sleep(0.1.seconds)
      timer.reschedule(Time.utc + 0.2.seconds)

      sleep(0.1.seconds)
      foo.should be_nil

      sleep(0.2.seconds)
      foo.should eq "bar"
    end
  end

  describe "#trigger" do
    it do
      foo = nil

      timer = Timer.new(1.second) do
        foo = "bar"
      end

      sleep(0.1.seconds)

      timer.trigger

      sleep(0.1.seconds)

      foo.should eq "bar"
    end
  end

  describe "#cancel" do
    it do
      foo = nil

      timer = Timer.new(0.5.seconds) do
        foo = "bar"
      end

      sleep(0.1.seconds)

      timer.cancel

      sleep(0.5.seconds)

      foo.should be_nil
    end
  end
end
