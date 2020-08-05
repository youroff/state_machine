defmodule StateMachine.Ecto.StateTypeTest do
  use ExUnit.Case, async: true

  defmodule StateMachineForEcto do
    use StateMachine

    defmachine do
      state :asleep
      state :awake
    end

    define_ecto_type(CustomMod)
  end

  test "generating Ecto.Type" do
    assert :error = StateMachineForEcto.CustomMod.cast(:non_existent_state)
    assert {:ok, :awake} = StateMachineForEcto.CustomMod.cast(:awake)
    assert {:ok, :asleep} = StateMachineForEcto.CustomMod.cast("asleep")

    assert :error = StateMachineForEcto.CustomMod.cast(:non_existent_state)
    assert {:ok, :awake} = StateMachineForEcto.CustomMod.cast(:awake)
    assert {:ok, :asleep} = StateMachineForEcto.CustomMod.cast("asleep")
  end

  test "raise CompileError when define_ecto_type called without StateMachine definition" do
    assert_raise CompileError, ~r"State Ecto type should be declared after state machine definition", fn ->
      Code.compile_string """
        defmodule StateMachineForEcto do
          use StateMachine
          define_ecto_type(CustomMod)

          defmachine do
            state :init
          end
        end
      """
    end
  end
end
