defmodule StateMachine.Ecto.IntegrationTest do
  use ExUnit.Case, async: true

  alias TestApp.{Repo, Cat, CatMachine}

  test "playing with cats" do
    {:ok, tom} = %Cat{name: "Tom", state: :asleep} |> Repo.insert()

    {:ok, tom_awake} = CatMachine.trigger_result(tom, :wake)
    tom = Repo.get!(Cat, tom_awake.id)

    assert tom.state == :awake

    # |> IO.inspect()
  end
end
