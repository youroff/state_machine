defmodule StateMachineIntrospectionTest do
  use ExUnit.Case
  alias StateMachine.{Context, State, Event, Introspection, Factory.Cat}
  import StateMachine.Factory

  setup do
    sm = %StateMachine{
      states: %{
        created: %State{name: :created},
        done: %State{name: :done}
      },
      events: %{
        finish: %Event{name: :finish}
      }
    }
    {:ok, %{sm: sm}}
  end

  test "all_states", %{sm: sm} do
    states = Introspection.all_states(sm)
    assert :created in states
    assert :done in states
  end

  test "all_events", %{sm: sm} do
    events = Introspection.all_events(sm)
    assert :finish in events
  end

  test "allowed_events" do
    ctx = Context.build(machine_cat(), %Cat{state: :asleep})
    assert :wake in Introspection.allowed_events(ctx)
  end
end
