defmodule StateMachine.Ecto.IntegrationTest do
  use ExUnit.Case, async: true

  alias TestApp.{Repo, Cat, CatMachine}

  test "playing with cats" do
    {:ok, tom} = %Cat{name: "Tom", state: :asleep, hungry: false} |> Repo.insert()

    {:ok, tom_awake} = CatMachine.trigger(tom, :wake)
    tom = Repo.get!(Cat, tom_awake.id)

    assert tom.state == :awake

    {:ok, tom_playing} = CatMachine.trigger(tom, :give_a_mouse)
    assert tom_playing.state == :playing

    {:ok, tom_still_playing} = CatMachine.trigger(tom_playing, :pet)
    assert tom_still_playing.state == :playing
  end
end
