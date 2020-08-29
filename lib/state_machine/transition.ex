defmodule StateMachine.Transition do
  @moduledoc """
  Transition module gathers together all of the actions that happen
  around transition from the old state to the new state in response to an event.
  """

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

  @doc """
  Checks if the transition is allowed in the current context. Returns boolean.
  """
  @spec is_allowed?(Context.t(model), t(model)) :: boolean when model: var
  def is_allowed?(ctx, transition) do
    Guard.check(ctx, transition)
  end

  @doc """
  Given populated context and Transition structure,
  sequentially runs all callbacks along with actual state update:

  * before(event)
  * before(transition)
  * before_leave(state)
  * before_enter(state)
  * *** (state update) ***
  * after_leave(state)
  * after_enter(state)
  * after(transition)
  * after(event)

  If any of the callbacks fails, all sequential ops are cancelled.
  """
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

  @doc """
  Private function for running `before_transition` callbacks.
  """
  @spec before(Context.t(model), t(model)) :: Context.t(model) when model: var
  def before(ctx, transition) do
    Callback.apply_chain(ctx, transition.before, :before_transition)
  end

  @doc """
  Private function for running `after_transition` callbacks.
  """
  @spec after_(Context.t(model), t(model)) :: Context.t(model) when model: var
  def after_(ctx, transition) do
    Callback.apply_chain(ctx, transition.after, :after_transition)
  end

  @doc """
  Private function for updating state.
  """
  @spec update_state(Context.t(model)) :: Context.t(model) when model: var
  def update_state(%{status: :init} = ctx) do
    ctx.definition.state_setter.(ctx, ctx.new_state)
  end

  def update_state(ctx), do: ctx

  @doc """
  Private function sets status to :done, unless it has failed before.
  """
  @spec finalize(Context.t(model)) :: Context.t(model) when model: var
  def finalize(%{status: :init} = ctx) do
    %{ctx | status: :done}
  end

  def finalize(ctx), do: ctx
end
