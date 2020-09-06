defmodule StateMachineStateTest do
  import ExUnit.CaptureLog
  require Logger
  use ExUnit.Case, async: true
  alias StateMachine.{State, Context, Transition, Factory.Cat}
  import StateMachine.Factory

  def yawn(cat) do
    Logger.info("#{cat.name} yawned")
  end

  test "state callbacks bypassed if the transition doesn't change the state" do
    ctx = put_in(machine_cat().states.asleep.after_leave, [&yawn/1])
    |> Context.build(%Cat{state: :asleep})

    refute capture_log(fn ->
      State.callback(%{ctx | transition: %Transition{from: :asleep, to: :asleep}}, :after_leave)
    end) =~ "Garfield yawned"

    assert capture_log(fn ->
      State.callback(%{ctx | transition: %Transition{from: :asleep, to: :awake}}, :after_leave)
    end) =~ "Garfield yawned"
  end
end
