defmodule StateMachineEventTest do
  use ExUnit.Case, async: true
  alias StateMachine.{Event, Context, Factory.Cat}
  import StateMachine.Factory

  test "is_allowed?" do
    ctx = Context.build(machine_cat(), %Cat{state: :asleep})
    assert Event.is_allowed?(ctx, event_wake())
    refute Event.is_allowed?(ctx, event_give_a_mouse())
  end
end
