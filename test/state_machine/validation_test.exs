defmodule StateMachineValidationTest do
  use ExUnit.Case, async: true
  alias StateMachine.{Validation, State, Event, Transition, Guard}
  import MonEx.Result

  test "validate_states_in_transitions" do
    sm = %StateMachine{
      states: %{
        created: %State{name: :created},
        done: %State{name: :done}
      },
      events: %{
        finish: %Event{name: :finish, transitions: [
          %Transition{from: :created, to: :done}
        ]}
      }
    }

    assert ok(_) = Validation.validate_states_in_transitions(sm)

    falty_sm = %{sm | events: Map.put(sm.events, :falty, %Event{
      name: :falty, transitions: [
        %Transition{from: :created, to: :nowhere}
      ]
    })}
    assert error(es) = Validation.validate_states_in_transitions(falty_sm)
    assert "Undefined state 'nowhere' is used in transition on 'falty' event." in es
  end

  test "validate_transitions_determinism" do
    sm = %StateMachine{
      states: %{
        created: %State{name: :created},
        done: %State{name: :done}
      },
      events: %{
        finish: %Event{name: :finish, transitions: [
          %Transition{from: :created, to: :created, guards: [%Guard{fun: &List.first/1, arity: 1}]},
          %Transition{from: :created, to: :done}
        ]}
      }
    }
    assert ok(_) = Validation.validate_transitions_determinism(sm)

    falty_sm = %{sm | events: %{
      finish: %Event{name: :finish, transitions: [
        %Transition{from: :created, to: :done},
        %Transition{from: :created, to: :created, guards: [%Guard{fun: &List.first/1, arity: 1}]}
      ]}
    }}
    assert error(es) = Validation.validate_transitions_determinism(falty_sm)
    assert "Event 'finish' already has an unguarded transition from 'created'; additional transition to 'created' will never run." in es
  end
end
