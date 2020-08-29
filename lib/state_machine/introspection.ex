defmodule StateMachine.Introspection do
  @moduledoc """
  Introspection functions allow you to collect and analyze meta information about state machine in runtime.
  For example, you might want to send the full list of states or events to the front-end, so that appropriate
  control or scale could be rendered. It is also possible to generate the list of currently allowed events,
  but be careful, this operation can be expensive if you use guards with side-effects.
  """

  alias StateMachine.{Event, Context}

  @doc """
  Returns a list of all states of the supplied state machine definition.
  """
  @spec all_states(StateMachine.t(any)) :: list(atom)
  def all_states(sm) do
    Map.keys(sm.states)
  end

  @doc """
  Returns a list of all events of the supplied state machine definition.
  """
  @spec all_events(StateMachine.t(any)) :: list(atom)
  def all_events(sm) do
    Map.keys(sm.events)
  end

  @doc """
  Returns a list of available events. This function takes a context with populated model,
  this is necessary to get a current state.
  """
  @spec allowed_events(Context.t(any)) :: list(atom())
  def allowed_events(ctx) do
    Map.values(ctx.definition.events)
    |> Enum.filter(&Event.is_allowed?(ctx, &1))
    |> Enum.map(& &1.name)
  end
end
