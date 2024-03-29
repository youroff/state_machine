defmodule StateMachine.Ecto.EnumTest do
  use ExUnit.Case, async: true

  defmodule GeneralEnum do
    require StateMachine.Ecto
    StateMachine.Ecto.define_enum([:what, :lol])
  end

  test "generating Ecto.Type" do
    assert :error = GeneralEnum.cast(:non_existent_state)
    assert {:ok, :what} = GeneralEnum.cast(:what)
    assert {:ok, :lol} = GeneralEnum.cast("lol")

    assert {:ok, :non_existent_state} = GeneralEnum.load("non_existent_state")
    assert {:ok, :what} = GeneralEnum.load("what")

    assert {:ok, "what"} = GeneralEnum.dump(:what)
    assert :error = GeneralEnum.dump(:non_existent_state)

    assert GeneralEnum.equal? :what, "what"
  end
end
