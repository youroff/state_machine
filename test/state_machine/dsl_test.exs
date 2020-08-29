defmodule StateMachineDSLTest do
  use ExUnit.Case, async: true
  doctest StateMachine

  @compile {:no_warn_undefined, Cat}

  test "life-like statemachine compilation" do
    Code.compile_string """
      defmodule Cat do
        use StateMachine

        defstruct [:name, :custom, hungry: true]

        defmachine field: :custom do
          state :asleep
          state :awake
          state :angry
          state :playing
          state :eating, after_enter: &Cat.feed_up/1

          event :wake do
            transition from: :asleep, to: :awake
          end

          event :wash do
            transition from: :awake, to: :angry, after: &Cat.wash/0
          end

          event :give_a_mouse do
            transition from: :awake, to: :playing, unless: &Cat.hungry/1
            transition from: :awake, to: :eating, if: &Cat.hungry/1
            transition from: :playing, to: :eating
          end

          event :pet do
            transition from: [:eating, :awake], to: :playing
          end

          event :sing_a_lullaby do
            transition from: :awake, to: :asleep
            transition from: :playing, to: :asleep
          end
        end

        def hungry(cat) do
          cat.hungry
        end

        def feed_up(cat) do
          {:ok, %{cat | hungry: false}}
        end

        def wash do
          {:error, "Your cat is broken now"}
        end
      end
    """
    cat = struct(Cat, %{name: "Bobik", custom: :asleep})
    assert :wake in Cat.allowed_events(cat)
    wake_ctx = Cat.trigger_with_context(cat, :wake)
    assert wake_ctx.status == :done
    assert wake_ctx.old_state == :asleep
    assert wake_ctx.new_state == :awake
    assert wake_ctx.model.custom == :awake
    assert wake_ctx.model.hungry

    assert :give_a_mouse in Cat.allowed_events(wake_ctx.model)
    assert :sing_a_lullaby in Cat.allowed_events(wake_ctx.model)
    eating_ctx = Cat.trigger_with_context(wake_ctx.model, :give_a_mouse)
    assert eating_ctx.status == :done
    assert eating_ctx.old_state == :awake
    assert eating_ctx.new_state == :eating
    assert eating_ctx.model.custom == :eating
    refute eating_ctx.model.hungry

    assert :pet in Cat.allowed_events(eating_ctx.model)
    playing_ctx = Cat.trigger_with_context(eating_ctx.model, :pet, "Some payload")
    assert playing_ctx.status == :done
    assert playing_ctx.old_state == :eating
    assert playing_ctx.new_state == :playing
    assert playing_ctx.model.custom == :playing
    assert playing_ctx.payload == "Some payload"

    assert {:error, {:event, "Couldn't resolve event"}} = Cat.trigger(cat, :something)
    assert {:error, {:transition, "Couldn't resolve transition"}} = Cat.trigger(cat, :pet)

    assert {:ok, awake_cat} = Cat.trigger(cat, :wake)
    assert {:error, {:after_transition, "Your cat is broken now"}} = Cat.trigger(awake_cat, :wash)

    assert :give_a_mouse in Cat.allowed_events(playing_ctx.model)
    assert :sing_a_lullaby in Cat.allowed_events(playing_ctx.model)
  end

  test "raise CompileError when state machine is not defined, but `use StateMachine` present" do
    assert_raise CompileError, ~r"Define state machine using `defmachine` macro", fn ->
      Code.compile_string """
        defmodule DummyStateMachine1 do
          use StateMachine
        end
      """
    end
  end

  test "raise CompileError when describing state outside of defmachine" do
    assert_raise CompileError, ~r"Calling `state` outside of state machine definition", fn ->
      Code.compile_string """
        defmodule DummyStateMachine2 do
          use StateMachine

          defmachine do
          end

          state :some
        end
      """
    end
  end

  test "raise CompileError when describing event outside of defmachine" do
    assert_raise CompileError, ~r"Calling `event` outside of state machine definition", fn ->
      Code.compile_string """
        defmodule DummyStateMachine3 do
          use StateMachine

          defmachine do
          end

          event :some do
          end
        end
      """
    end
  end

  test "raise CompileError when describing transition outside of event" do
    assert_raise CompileError, ~r"Calling `transition` outside of `event` block", fn ->
      Code.compile_string """
        defmodule DummyStateMachine4 do
          use StateMachine

          defmachine do
            transition from: :some, to: :other
          end
        end
      """
    end
  end

  test "declares auxiliary functions automatically" do
    Code.compile_string """
      defmodule DummyStateMachine5 do
        use StateMachine

        defmachine do
        end
      end
    """
    assert function_exported?(DummyStateMachine5, :all_states, 0)
    assert function_exported?(DummyStateMachine5, :all_events, 0)
    assert function_exported?(DummyStateMachine5, :allowed_events, 1)
    assert function_exported?(DummyStateMachine5, :trigger, 2)
    # TODO: to be continued with more functions
  end

  test "validation on existing states" do
    assert_raise CompileError, ~r"Undefined state 'something_else' is used in transition on 'do' event.", fn ->
      Code.compile_string """
        defmodule GhostStatesExample do
          use StateMachine

          defmachine  do
            state :start
            state :finish

            event :do do
              transition from: :start, to: :something_else
            end
          end
        end
      """
    end
  end

  test "validation on determinism of transitions" do
    assert_raise CompileError, ~r"Event 'do' already has an unguarded transition from 'start'; additional transition to 'wait' will never run.", fn ->
      Code.compile_string """
        defmodule NonDeterministicExample do
          use StateMachine

          defmachine  do
            state :start
            state :finish
            state :wait

            event :do do
              transition from: :start, to: :finish # Yet adding a guard here would clear the error
              transition from: :start, to: :wait
            end
          end
        end
      """
    end
  end
end
