# Versatile Timer class which relies on Crystal scheduler.
#
# Basic example:
#
# ```
# Timer.new(1.second) do
#   puts "1 second has passed!"
# end
#
# sleep
# ```
#
# Example with `select`:
#
# ```
# channel = Channel(Nil).new
#
# select
# when channel.receive
#   puts "Never happens"
# when Timer.new(1.second)
#   puts "Timeout!"
# end
#
# sleep # Will print "Timeout!" after 1 second
# ```
#
# You can `#postpone` and `#reschedule` a timer, but note that the latter has bigger
# performance impact and should only be used when rescheduling to an earlier time.
#
# ```
# at = Time.utc_now + 5.minutes
#
# timer = Timer.new(at) do
#   puts "Triggered"
# end
#
# # OK, will trigger in 6 minutes from now
# timer.postpone(1.minute)
#
# # Worse performance than `#postpone`, but still works
# timer.reschedule(Time.utc_now + 6.minutes)
#
# # OK, will trigger in 1 minute from now (i.e. eariler)
# timer.reschedule(Time.utc_now + 1.minute)
# ```
#
# Note that a timer can be scheduled at a moment in the past, which means that it
# would run immediately after given control by Crystal scheduler.
#
# You can also `#trigger` the timer immediately (still calling the block in
# another fiber), or `#cancel` it completely.
class Timer
  # When the timer is scheduled to be triggered at.
  property at : Time

  # Whether is the timer already triggered.
  getter? completed : Bool = false

  # Whether is the timer cancelled.
  getter? cancelled : Bool = false

  @channel = Channel(Nil).new(1)
  protected getter channel

  @active_fiber_id : Float64
  @cancelled_fiber_ids : Hash(Float64, Bool)?

  # Execute the *block* *at* the moment of time.
  def initialize(@at : Time, &block)
    @active_fiber_id = schedule

    spawn do
      @channel.receive

      if !@cancelled
        @completed = true
        block.call
      end
    end
  end

  # Execute the *block* *in* some time span.
  def self.new(in : Time::Span, &block)
    new(Time.utc_now + in, &block)
  end

  # :nodoc:
  # This method is used with `select` keyword.
  def self.new_select_action(*args)
    instance = new(*args, &->{})
    instance.channel.receive_select_action
  end

  # Postpone the execution *by* a time span.
  def postpone(by : Time::Span)
    @at += by
  end

  # Reschedule the timer *at* desired time.
  #
  # NOTE: For better performance, use this method only when rescheduling to an
  # eariler moment of time. For later execution `#postpone` is preferrable.
  def reschedule(@at : Time)
    unless hash = @cancelled_fiber_ids
      hash = @cancelled_fiber_ids = Hash(Float64, Bool).new
    end

    hash[@active_fiber_id] = true

    fiber_id = loop do
      temp = rand
      break temp unless hash.has_key?(temp)
    end

    schedule(fiber_id)
  end

  # Trigger the execution immediately.
  def trigger
    return if @completed || @cancelled
    @channel.send(nil)
  end

  # Cancel this timer.
  def cancel
    return if @completed || @cancelled
    @cancelled = true
    @channel.send(nil)
  end

  protected def schedule(fiber_id = rand)
    spawn do
      loop do
        sleep({Time::Span.zero, @at - Time.utc_now}.max)

        if @completed || @cancelled
          break
        end

        if @cancelled_fiber_ids.try &.delete(fiber_id)
          break
        end

        if Time.utc_now < @at
          next
        end

        break @channel.send(nil)
      end
    end

    fiber_id
  end
end
