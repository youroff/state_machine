defmodule StateMachineUtilsTest do
  use ExUnit.Case
  import StateMachine.Utils

  test "keyword_splat" do
    assert ["a"] == keyword_splat([p: "a"], :p)
    assert ["a", "b"] == keyword_splat([p: ["a", "b"]], :p)
    assert [] == keyword_splat([p: "a"], :q)
    assert ["ok"] == keyword_splat([p: "a"], :q, ["ok"])
  end

  describe "normalize_function" do
    test "when a function is passed" do
      f = fn _ -> 0 end
      assert f == normalize_function(:foo, f)
    end

    test "when a module and atom are passed" do
      assert normalize_function(String, :codepoints) == (&String.codepoints/1)
    end

    test "when the second argument is invalid" do
      assert_raise ArgumentError, fn ->
        normalize_function(:foo, 2)
      end
    end
  end
end
