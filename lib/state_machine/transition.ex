defmodule StateMachine.Transition do
  alias StateMachine.{Transition, Event, State, Context, Callback, Guard}

  @type t(model) :: %__MODULE__{
    from:   atom,
    to:     atom,
    before: list(Callback.t(model)),
    after:  list(Callback.t(model)),
    guards: list(Guard.t(model))
  }

  @enforce_keys [:from, :to]
  defstruct [
    :from,
    :to,
    before: [],
    after:  [],
    guards: []
  ]

  @spec is_allowed?(Context.t(model), t(model)) :: boolean when model: var
  def is_allowed?(ctx, transition) do
    Guard.check(ctx, transition)
  end

  @spec run(Context.t(model), t(model)) :: Context.t(model) when model: var
  def run(ctx, transition) do
    %{ctx | new_state: transition.to}
    |> Event.before()
    |> Transition.before(transition)
    |> State.before_leave()
    |> State.before_enter()
    |> Transition.update_state()
    |> State.after_leave()
    |> State.after_enter()
    |> Transition.after_(transition)
    |> Event.after_()
    |> Transition.finalize()
  end

  @spec before(Context.t(model), t(model)) :: Context.t(model) when model: var
  def before(ctx, transition) do
    Callback.apply_chain(ctx, transition.before)
  end

  @spec after_(Context.t(model), t(model)) :: Context.t(model) when model: var
  def after_(ctx, transition) do
    Callback.apply_chain(ctx, transition.after)
  end

  @spec update_state(Context.t(model)) :: Context.t(model) when model: var
  def update_state(%{status: :init} = ctx) do
    ctx.definition.state_setter.(ctx, ctx.new_state)
  end

  def update_state(ctx), do: ctx

  @spec finalize(Context.t(model)) :: Context.t(model) when model: var
  def finalize(%{status: :init} = ctx) do
    %{ctx | status: :done}
  end

  def finalize(ctx), do: ctx
end
