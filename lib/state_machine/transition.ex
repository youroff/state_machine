defmodule StateMachine.Transition do
  @moduledoc """
  Transition module gathers together all of the actions that happen
  around transition from the old state to the new state in response to an event.
  """

  alias StateMachine.{Context, Callback, Guard}

  @type t(model) :: %__MODULE__{
    from:   atom,
    to:     atom,
    before: list(Callback.t(model)),
    after:  list(Callback.t(model)),
    guards: list(Guard.t(model))
  }

  @type callback_pos() :: :before | :after
  @type state_callback_pos() :: :before_enter | :after_enter | :before_leave | :after_leave

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
    |> event_callback(:before)
    |> callback(:before)
    |> state_callback(:before_leave)
    |> state_callback(:before_enter)
    |> update_state()
    |> state_callback(:after_leave)
    |> state_callback(:after_enter)
    |> callback(:after)
    |> event_callback(:after)
    |> finalize()
  end

  @doc false
  @spec event_callback(Context.t(model), callback_pos()) :: Context.t(model) when model: var
  def event_callback(ctx, pos) do
    callbacks = Map.get(Map.get(ctx.definition.events, ctx.event), pos)
    Callback.apply_chain(ctx, callbacks, event_step(pos))
  end

  @doc false
  @spec state_callback(Context.t(model), state_callback_pos()) :: Context.t(model) when model: var
  def state_callback(ctx, pos) do
    if loop?(ctx.transition) do
      ctx
    else
      source = if pos in [:before_enter, :after_enter], do: :to, else: :from
      state_name = Map.get(ctx.transition, source)
      state = Map.get(ctx.definition.states, state_name)
      Callback.apply_chain(ctx, Map.get(state, pos), pos)
    end
  end

  @doc """
  Private function for running Transition callbacks.
  """
  @spec callback(Context.t(model), callback_pos()) :: Context.t(model) when model: var
  def callback(ctx, pos) do
    callbacks = Map.get(ctx.transition, pos)
    Callback.apply_chain(ctx, callbacks, transition_step(pos))
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

  defp event_step(:before), do: :before_event
  defp event_step(:after), do: :after_event

  defp transition_step(:before), do: :before_transition
  defp transition_step(:after), do: :after_transition
end
