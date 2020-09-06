defmodule StateMachineCallbackTest do
  use ExUnit.Case, async: true
  alias StateMachine.{Factory.Cat, Callback, Context}
  import StateMachine.Factory

  defmodule TestCallbacks do
    def unary_to_model(model) do
      {:ok, %{model | name: "Renamed cat"}}
    end

    def unary_to_error(_model) do
      {:error, :unary_error}
    end

    def unary_to_effect(_model) do
      :ok
    end

    def binary_to_context(_model, ctx) do
      {:ok, %{ctx | status: :failed, error: :replaced_context}}
    end

    def binary_to_model(model, _ctx) do
      {:ok, %{model | name: "Renamed cat"}}
    end

    def binary_to_error(_model, _ctx) do
      {:error, :binary_error}
    end

    def binary_to_effect(_model, _ctx) do
      :ok
    end

    def side_effect_ok() do
      :ok
    end

    def side_effect_error() do
      {:error, :side_effect_error}
    end
  end

  test "arities" do
    context = Context.build(machine_cat(), %Cat{state: :asleep})

    ctx = Callback.apply_callback(context, &TestCallbacks.unary_to_model/1, :test)
    assert ctx.model.name == "Renamed cat"

    ctx = Callback.apply_callback(context, &TestCallbacks.unary_to_error/1, :test)
    assert ctx.status == :failed
    assert ctx.error == {:test, :unary_error}

    ctx = Callback.apply_callback(context, &TestCallbacks.unary_to_effect/1, :test)
    assert ctx == context

    ctx = Callback.apply_callback(context, &TestCallbacks.binary_to_context/2, :test)
    assert ctx.status == :failed
    assert ctx.error == :replaced_context

    ctx = Callback.apply_callback(context, &TestCallbacks.binary_to_model/2, :test)
    assert ctx.model.name == "Renamed cat"

    ctx = Callback.apply_callback(context, &TestCallbacks.binary_to_error/2, :test)
    assert ctx.status == :failed
    assert ctx.error == {:test, :binary_error}

    ctx = Callback.apply_callback(context, &TestCallbacks.binary_to_effect/2, :test)
    assert ctx == context

    ctx = Callback.apply_callback(context, &TestCallbacks.side_effect_ok/0, :test)
    assert ctx == context

    ctx = Callback.apply_callback(context, &TestCallbacks.side_effect_error/0, :test)
    assert ctx.status == :failed
    assert ctx.error == {:test, :side_effect_error}
  end
end
