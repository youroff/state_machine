defmodule StateMachine.Event do
  @moduledoc """
  Event is a container for transitions. It is identified by name (atom) and can contain arbitrary number of transtitions.

  One important thing is that it's disallowed to have more than one unguarded transition from the state, since this
  would introduce a "non-determinism" (or rather just discard the latter transition). We loosely allow guarded transitions
  from the same state, but it doesn't guarantee anything: if guards always return true, we're back to where we were before.
  """

  alias StateMachine.{Callback, Context, Error, Event, Guard, Transition}

  @type t(model) :: %__MODULE__{
    name:         atom,
    transitions:  list(Transition.t(model)),
    before:       list(Callback.t(model)),
    after:        list(Callback.t(model)),
    guards:       list(Guard.t(model))
  }

  @type callback_pos() :: :before | :after

  @enforce_keys [:name]
  defstruct [
    :name,
    transitions:  [],
    before:       [],
    after:        [],
    guards:       []
  ]

  @doc """
  Checks if the event is allowed in the current context. First it makes sure that all guards
  of the event return `true`, then it scans transitions for the matching one. Match is determined
  by the source state and passing of all guards as well.
  """
  @spec is_allowed?(Context.t(model), t(model) | atom) :: boolean when model: var
  def is_allowed?(ctx, event) do
    :ok == guard_check(ctx, event) and match?({:ok, _}, find_transition(ctx, event))
  end

  @doc """
  This is an entry point for transition. By running this function with populated context, event
  and optional payload, you tell state machine to try to move to the next state.
  It returns an updated context.
  """
  @type errors(model) ::
          Error.GuardNotAllow.t(model)
          | Error.UnresolvedTransition.t(model)
          | Error.UnknownEvent.t(model)
          | Error.CallbackError.t(model)

  @spec trigger(Context.t(model), atom, any) :: {:ok, Context.t(model)} | {:error, errors(model)}
        when model: var
  def trigger(ctx, event, payload \\ nil) do
    context = %{ctx | payload: payload, event: event}

    with {:ok, %Event{} = e} <- find_event(context, event),
         :ok <- guard_check(context, e),
         {:ok, %Transition{} = t} <- find_transition(context, e) do
      Transition.run(%{context | transition: t})
    end
  end

  @doc """
  Private function for running Event callbacks.
  """
  @spec callback(Context.t(model), callback_pos()) ::
          {:ok, Context.t(model)} | {:error, Error.CallbackError.t(model)}
        when model: var
  def callback(ctx, pos) do
    callbacks = Map.get(ctx.definition.events[ctx.event], pos)
    Callback.apply_chain(ctx, callbacks, :"#{pos}_event")
  end

  @spec guard_check(Context.t(model), t(model)) ::
          :ok | {:error, Error.GuardNotAllow.t(model)}
        when model: var
  defp guard_check(ctx, event) do
    if Guard.check(ctx, event),
      do: :ok,
      else: {:error, %Error.GuardNotAllow{context: ctx, event: event.name}}
  end

  @spec find_transition(Context.t(model), t(model)) ::
          {:ok, Transition.t(model)} | {:error, Error.UnresolvedTransition.t(model)}
        when model: var
  defp find_transition(ctx, event) do
    state = ctx.definition.state_getter.(ctx)
    error = {:error, %Error.UnresolvedTransition{context: ctx, event: event.name}}

    Enum.find_value(event.transitions, error, fn transition ->
      if transition.from == state && Transition.is_allowed?(ctx, transition) do
        {:ok, transition}
      end
    end)
  end

  @spec find_event(Context.t(model), atom) ::
          {:ok, t(model)} | {:error, Error.UnknownEvent.t(model)}
        when model: var
  defp find_event(ctx, event_name) do
    case Map.get(ctx.definition.events, event_name) do
      %Event{} = e -> {:ok, e}
      _ -> {:error, %Error.UnknownEvent{context: ctx, event: event_name}}
    end
  end
end
