defmodule StateMachineEventTest do
  use ExUnit.Case, async: true
  alias StateMachine.{Event, Context, Factory.Cat}
  import StateMachine.Factory
  # import MonEx.Option

  # test "find_transition" do
  #   ctx = Context.build(machine_cat(), %Cat{state: :asleep})

  #   assert some(transition) = Event.find_transition(ctx, event_wake())
  #   assert transition.from == :asleep
  #   assert transition.to == :awake

  #   assert none() = Event.find_transition(ctx, event_give_a_mouse())

  #   new_ctx = Context.build(machine_cat(), %Cat{state: :awake})
  #   assert some(transition) = Event.find_transition(new_ctx, event_give_a_mouse())
  #   assert transition.from == :awake
  #   assert transition.to == :playing
  # end

  test "is_allowed?" do
    ctx = Context.build(machine_cat(), %Cat{state: :asleep})
    assert Event.is_allowed?(ctx, event_wake())
    refute Event.is_allowed?(ctx, event_give_a_mouse())
  end
end
