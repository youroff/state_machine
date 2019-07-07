defmodule StateMachineContextTest do
  use ExUnit.Case
  alias StateMachine.Context
  import StateMachine.Factory

  test "build" do
    cat = %StateMachine.Factory.Cat{}
    sm = machine_cat()
    ctx = Context.build(sm, cat)
    assert ctx.old_state == cat.state
    assert ctx.model == cat
    assert ctx.definition == sm
  end
end
