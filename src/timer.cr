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
# You can `#postpone` and `#reschedule` a timer. The latter has bigger
# performance impact if rescheduling at an earlier moment of time.
#
# ```
# at = Time.utc + 5.minutes
#
# timer = Timer.new(at) do
#   puts "Triggered"
# end
#
# # OK, will trigger in 6 minutes from now
# timer.postpone(1.minute)
#
# # ditto
# timer.reschedule(Time.utc + 6.minutes)
#
# # Worse performance but still acceptable
# timer.reschedule(Time.utc + 1.minute)
# ```
#
# Note that a timer can be scheduled at a moment in the past, which means that it
# would run immediately after given control by the Crystal scheduler.
#
# You can also `#trigger` a timer (still calling the block in another fiber) or
# `#cancel` it completely.
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
    new(Time.utc + in, &block)
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
  # NOTE: Rescheduling at earlier time has bigger performance impact than
  # at a moment in the future.
  def reschedule(at : Time)
    if at >= @at
      @at += (at - @at)
    else
      @at = at

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
        sleep({Time::Span.zero, @at - Time.utc}.max)

        if @completed || @cancelled
          break
        end

        if @cancelled_fiber_ids.try &.delete(fiber_id)
          break
        end

        if Time.utc < @at
          next
        end

        break @channel.send(nil)
      end
    end

    fiber_id
  end
end
