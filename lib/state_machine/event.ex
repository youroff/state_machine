defmodule StateMachine.Event do
  alias StateMachine.{Event, Transition, Context, Callback, Guard}
  import MonEx.Option

  @type t(model) :: %__MODULE__{
    name:         atom,
    transitions:  list(Transition.t(model)),
    before:       list(Callback.t(model)),
    after:        list(Callback.t(model)),
    guards:       list(Guard.t(model)),
  }

  @enforce_keys [:name]
  defstruct [
    :name,
    transitions:  [],
    before:       [],
    after:        [],
    guards:       []
  ]

  @spec is_allowed?(Context.t(model), t(model) | atom) :: boolean when model: var
  def is_allowed?(ctx, event) do
    find_transition(ctx, event) |> is_some()
  end

  @spec trigger(Context.t(model), atom, any) :: Context.t(model) when model: var
  def trigger(ctx, event, payload \\ nil) do
    context = %{ctx | payload: payload, event: event}
    with %Event{} = e <- Map.get(context.definition.events, event) do
      case find_transition(context, e) do
        some(transition) ->
          Transition.run(context, transition)
        none() ->
          %{ctx | status: :rejected}
      end
    else
      _ -> %{ctx | status: :impossible}
    end
  end

  @spec before(Context.t(model)) :: Context.t(model) when model: var
  def before(ctx) do
    Callback.apply_chain(ctx, ctx.definition.events[ctx.event].before)
  end

  @spec after_(Context.t(model)) :: Context.t(model) when model: var
  def after_(ctx) do
    Callback.apply_chain(ctx, ctx.definition.events[ctx.event].after)
  end

  @spec find_transition(Context.t(model), t(model)) :: MonEx.Option.t(Transition.t(model)) when model: var
  defp find_transition(ctx, event) do
    if Guard.check(ctx, event) do
      Enum.find(event.transitions, fn transition ->
        transition.from == ctx.old_state && Transition.is_allowed?(ctx, transition)
      end) |> to_option
    else
      none()
    end
  end
end
