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

  @type callback_pos() :: :before | :after

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
  @spec run(Context.t(model)) :: Context.t(model) when model: var
  def run(ctx) do
    ctx
    |> Event.callback(:before)
    |> Transition.callback(:before)
    |> State.callback(:before_leave)
    |> State.callback(:before_enter)
    |> Transition.update_state()
    |> State.callback(:after_leave)
    |> State.callback(:after_enter)
    |> Transition.callback(:after)
    |> Event.callback(:after)
    |> Transition.finalize()
  end

  @doc """
  Private function for running Transition callbacks.
  """
  @spec callback(Context.t(model), callback_pos()) :: Context.t(model) when model: var
  def callback(ctx, pos) do
    callbacks = Map.get(ctx.transition, pos)
    Callback.apply_chain(ctx, callbacks, :"#{pos}_transition")
  end

  @doc """
  Private function for updating state.
  """
  @spec update_state(Context.t(model)) :: Context.t(model) when model: var
  def update_state(%{status: :init} = ctx) do
    ctx.definition.state_setter.(ctx, ctx.transition.to)
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

  @doc """
  True if transition is a loop, i.e. doesn't change state.
  """
  @spec loop?(t(any)) :: boolean
  def loop?(%{from: s, to: s}), do: true
  def loop?(_), do: false

  @spec passthrough(Context.t(model)) :: t(model) when model: var
  def passthrough(ctx) do
    state = ctx.definition.state_getter.(ctx)
    %__MODULE__{from: state, to: state}
  end
end
