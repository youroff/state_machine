defmodule StateMachine.Introspection do
  alias StateMachine.{Event, Context}

  @spec all_states(StateMachine.t(any)) :: list(atom)
  def all_states(sm) do
    Map.keys(sm.states)
  end

  @spec all_events(StateMachine.t(any)) :: list(atom)
  def all_events(sm) do
    Map.keys(sm.events)
  end

  @spec allowed_events(Context.t(any)) :: list(atom())
  def allowed_events(ctx) do
    Map.values(ctx.definition.events)
    |> Enum.filter(&Event.is_allowed?(ctx, &1))
    |> Enum.map(& &1.name)
  end
end
