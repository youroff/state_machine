defmodule StateMachineUtilsTest do
  use ExUnit.Case
  import StateMachine.Utils

  test "keyword_splat" do
    assert ["a"] == keyword_splat([p: "a"], :p)
    assert ["a", "b"] == keyword_splat([p: ["a", "b"]], :p)
    assert [] == keyword_splat([p: "a"], :q)
    assert ["ok"] == keyword_splat([p: "a"], :q, ["ok"])
  end
end
