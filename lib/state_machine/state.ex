defmodule StateMachine.State do
  @moduledoc """
  State module provides a structure describing a state in the state machine definition.
  It stores state name along with various callbacks to run before/after leaving/entering a state.
  Another purpose of the module is to define a behaviour for state get/setters along with the default implementation.

  The state get/setters for basic structures and Ecto records are provided out of the box.
  """

  alias StateMachine.{Context, Callback, Transition}

  @callback get(ctx :: Context.t(any)) :: atom()
  @callback set(ctx :: Context.t(model), state :: atom) :: Context.t(model) when model: var

  @type t(model) :: %__MODULE__{
    name:  atom,
    before_enter: list(Callback.t(model)),
    after_enter: list(Callback.t(model)),
    before_leave: list(Callback.t(model)),
    after_leave: list(Callback.t(model))
  }

  @type callback_pos() :: :before_enter | :after_enter | :before_leave | :after_leave

  @enforce_keys [:name]
  defstruct [
    :name,
    before_enter: [],
    after_enter: [],
    before_leave: [],
    after_leave: []
  ]

  @doc """
  Private function for running state callbacks.
  """
  @spec callback(Context.t(model), callback_pos()) :: Context.t(model) when model: var
  def callback(ctx, pos) do
    if Transition.loop?(ctx.transition) do
      ctx
    else
      source = String.ends_with?(to_string(pos), "_enter") && :to || :from
      state_name = Map.get(ctx.transition, source)
      state = ctx.definition.states[state_name]
      Callback.apply_chain(ctx, Map.get(state, pos), pos)
    end
  end

  @doc """
  Default implementation of a state getter.
  """
  @spec get(Context.t(any)) :: atom()
  def get(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end

  @doc """
  Default implementation of a state setter.
  """
  @spec set(Context.t(model), atom()) :: Context.t(model) when model: var
  def set(ctx, state) do
    %{ctx | model: Map.put(ctx.model, ctx.definition.field, state)}
  end
end
