defmodule StateMachineGuardTest do
  use ExUnit.Case, async: true
  alias StateMachine.{Event, Guard, Context}
  # import StateMachine.Factory
  # import MonEx.Option

  test "prepare" do
    [one, two, three] = Guard.prepare(if: &guard_one/2, unless: [&__MODULE__.guard_two/1, &guard_three/0])

    refute one.inverted
    assert one.arity == 2
    assert is_function(one.fun, 2)

    assert two.inverted
    assert two.arity == 1
    assert is_function(two.fun, 1)

    assert three.inverted
    assert three.arity == 0
    assert is_function(three.fun, 0)
  end

  test "check" do
    guards = Guard.prepare(if: &guard_one/2, unless: &guard_two/1)
    event = %Event{name: :test, guards: guards}

    context = %Context{definition: %StateMachine{}, model: %{one: true, two: false}}

    assert Guard.check(context, event)
    refute Guard.check(%{context | model: %{one: true, two: true}}, event)
  end

  def guard_one(_, ctx) do
    ctx.model.one
  end

  def guard_two(model) do
    model.two
  end

  def guard_three do
    false
  end
end
