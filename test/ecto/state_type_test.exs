defmodule StateMachine.Ecto.StateTypeTest do
  use ExUnit.Case, async: true

  defmodule StateMachineForEcto do
    use StateMachine

    defmachine repo: TestApp.Repo, state_type: CustomMod do
      state :asleep
      state :awake
    end
  end

  alias StateMachineForEcto.CustomMod

  test "generating Ecto.Type" do
    assert :error = CustomMod.cast(:non_existent_state)
    assert {:ok, :awake} = CustomMod.cast(:awake)
    assert {:ok, :asleep} = CustomMod.cast("asleep")

    # Some phased out states can be present in the DB, we probably don't want to crash here
    assert {:ok, :non_existent_state} = CustomMod.load("non_existent_state")
    assert {:ok, :awake} = CustomMod.load("awake")

    assert {:ok, "awake"} = CustomMod.dump(:awake)
    assert :error = CustomMod.dump(:non_existent_state)

    assert CustomMod.equal? :awake, "awake"
  end
end
